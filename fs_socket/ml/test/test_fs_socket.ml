open Fs_socket

module Response = struct
  type t = { return_value: int }
  let make return_value = { return_value }
  let return_value t = t.return_value
  let jsont =
    let open Jsont in
    Object.map make
    |> Object.mem "return_value" Jsont.int ~enc:return_value
    |> Object.finish
end

module Request = struct
  type t = { module_name: string }
  let make module_name = { module_name }
  let module_name t = t.module_name
  let jsont =
    let open Jsont in
    Object.map make
    |> Object.mem "module_name" Jsont.string ~enc:module_name
    |> Object.finish
end

let () =
  let open Eio in
  Eio_main.run @@ fun env ->
  Switch.run @@ fun sw ->
  let vardir =
    let homedir = Path.(Stdenv.fs env / Sys.getenv "HOME") in
    Path.(homedir / ".var")
  and process_mgr = Stdenv.process_mgr env in
  let session_name = "example_session" in
  Namespace.with_make ~vardir session_name @@ fun ~vardir ~session_name ->
  Namespace_watch.all ~process_mgr ~ejsont:Response.jsont ~fjsont:Request.jsont ~vardir ~session_name ~sw
  |> function seq, _ ->
  Switch.run @@ fun sw ->
  begin Fiber.fork ~sw @@ fun () ->
    seq |> Seq.fold_left (fun _ x ->
      Fs_socket.reply x @@ fun request ->
      let open Request in
      Response.make 1
    ) ()
    |> ignore
  end
