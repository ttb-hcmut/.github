module Path0 = struct
  open Eio 
  let save ~process_mgr path str =
    Process.run process_mgr ["sh"; "-c"; "echo '" ^ str ^ "' > " ^ (Path.native_exn path)]
end

module type Serde = sig
  type t [@@deriving json]
end

let iter
(type input output)
(module I : Serde with type t = input)
(module O : Serde with type t = output)
process_mgr dir inode f =
  let open Eio in
  let socket = Path.(dir / inode) in
  Path.with_open_in socket begin fun socket ->
    Flow.read_all socket
    |> Jsont_bytesrw.decode_string I.jsont
    |> Result.get_ok
  end |> fun request ->
  let a, resolve_promise = Promise.create () in
  f Socket.{ resolve_promise ; input = request };
  Promise.await a
  |> Jsont_bytesrw.encode_string O.jsont
  |> Result.get_ok
  |> fun reply_str ->
  (* @fixme(kinten) This code should have been [Eio.Flow.copy_string reply_str socket]. But it didn't work with unix pipe for some reasons. The expected behavior is that (and this is implemened by the OS) it should wait for the other side to establish connection, then writing starts - this is pipe synchronization, and is expected in unix. However, this behavior doesn't apply when using [Eio.Flow.copy_string], the bytes were quietly dropped before pipe connection. Now I have to use a placeholder solution [Path0.save ~process_mgr socket reply_str], I have to shell-out and send data with an echo command; it works, but it's obviously bad and stupid *)
  Path0.save ~process_mgr socket reply_str;
  while (
    match Path.kind ~follow:false socket with
    | `Fifo -> true
    | `Not_found -> false
    | _ -> failwith "wtf"
  ) do () done

let iter ~i ~o ~process_mgr f socket =
  let open Eio in
  let dir = Path.(Socket.vardir socket / "fs_socket" / Socket.session_name socket)
  and cache_tbl = Hashtbl.create 100 in
  Switch.run @@ fun sw ->
  while true; do
    Path.read_dir dir
    |> List.iter @@ fun inode ->
      match Hashtbl.find cache_tbl inode with
    | v ->
      let can_remove = v in
      if Promise.is_resolved can_remove
      then Hashtbl.remove cache_tbl inode
    | exception Not_found ->
      Hashtbl.add cache_tbl inode
      ( Fiber.fork_promise ~sw @@ fun () ->
        iter i o process_mgr dir inode f
      )
  done;
  ()
