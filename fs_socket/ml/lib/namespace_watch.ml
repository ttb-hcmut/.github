module Fiber0 = struct
  let fork_resolver ~sw resolver f =
    Eio.Fiber.fork ~sw @@ fun () ->
      f ()
      |> Eio.Promise.resolve resolver
end

module Path0 = struct
  open Eio 
  let save ~process_mgr path str =
    Process.run process_mgr ["sh"; "-c"; "echo '" ^ str ^ "' > " ^ (Path.native_exn path)]
end

module type Serializable = sig
  type t
  val jsont: t Jsont.t
end

let all ~process_mgr ~ejsont ~fjsont ~vardir ~session_name ~sw =
  let open Eio in
  let dir = Path.(vardir / "fs_socket" / session_name)
  and stat_dircheck, end_dircheck = Promise.create ()
  and cache = Hashtbl.create 100
  and requests = Stream.create 0 in
  ( Fiber.fork ~sw @@ fun () ->
    Switch.run @@ fun sw ->
    while not (Promise.is_resolved stat_dircheck); do
      Path.read_dir dir
      |> Fiber.List.iter @@ fun inode ->
      let open Stream_syntax in
      match Hashtbl.find cache inode with
      | v ->
        let can_remove = v in
        if Promise.is_resolved can_remove
        then Hashtbl.remove cache inode
      | exception Not_found ->
        let can_remove, mark_removal = Promise.create () in
        Hashtbl.add cache inode can_remove;
        ( Fiber0.fork_resolver ~sw mark_removal @@ fun () ->
          let socket = Path.(dir / inode) in
          Path.with_open_in socket
            begin fun socket ->
              Flow.read_all socket
              |> Jsont_bytesrw.decode_string fjsont
              |> Result.get_ok
            end
          |> fun request ->
          let reply_v, r_promise_v = Promise.create () in
          requests += (r_promise_v, request);
          begin
            Promise.await reply_v
            |> Jsont_bytesrw.encode_string ejsont
            |> Result.get_ok
            |> fun reply_str ->
            Path0.save ~process_mgr socket reply_str;
          end;
          while (
            match Path.kind ~follow:false socket with `Fifo -> true | `Not_found -> false | _ -> failwith "wtf"
          ) do () done
        )
    done
  );
  let rec next () =
    let open Stream_syntax in
    match !requests with
    | None -> Seq.Nil
    | Some v -> Seq.Cons (v, next)
  and stop () =
    let open Stream_syntax in
    Promise.resolve end_dircheck ()
    ; !| requests in
  next, stop
