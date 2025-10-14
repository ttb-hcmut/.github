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

let test_simple () =
  let open Eio in
  Eio_main.run @@ fun env ->
  let vardir =
    let homedir = Path.(Stdenv.fs env / Sys.getenv "HOME") in
    Path.(homedir / ".var")
  and clock = Stdenv.clock env
  and process_mgr = Stdenv.process_mgr env in
  let name = "example_session" in
  Namespace.with_open_in ~vardir ~name @@ fun session ->
  Switch.run @@ fun sw ->
  ( Fiber.fork_daemon ~sw @@ fun () ->
    session |> Namespace_watch.iter
      ~process_mgr
      ~o:(module Response)
      ~i:(module Request)
      begin fun x ->
        Fs_socket.Socket.reply x @@ fun _ ->
        Response.make 1
      end;
    `Stop_daemon
  );
  Time.sleep clock 2.;
  Alcotest.(check bool)
    "session directory should exist"
    true Path.(is_directory (vardir / "fs_socket" / name))

open Alcotest;;

run "Fs_socket"
[ "activation",
  [ test_case "Simple" `Quick test_simple
  ]
]
