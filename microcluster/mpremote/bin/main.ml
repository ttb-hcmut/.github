open Mpremote

module Backend = struct
  exception Internal_failure of int

  let run process_mgr ~stdout ~stderr args =
    let open Eio in
    try Process.run process_mgr ~stdout ~stderr
      begin ["mpremote"] @ args end
    with Io (Process.E (Child_error (`Exited x)), _) -> raise (Internal_failure x)
end

let traceback =
  let open Re in
  str "Traceback (most recent call last):" |> compile

let ( ^. ) = Re.Group.get
let quoted x = "\"" ^ x ^ "\""

let prettify_file_location =
  let pattern =
    let open Re in
    seq [ str "  File \"" ; group (any |> rep1 |> shortest) ; str "\", line " ; group (alnum |> rep1) ; str ", in " ; group (any |> rep1 |> shortest) ]
    |> whole_string
    |> compile in
  Re.replace pattern ~f:begin fun groups ->
    let open Ansi_colors in
    Printf.sprintf "  File %s, line %s, in %s"
      (magenta @@ quoted @@ groups ^. 1)
      (magenta @@ groups ^. 2)
      (magenta @@ groups ^. 3)
  end

let prettify_exception_msg =
  let pattern =
    let open Re in
    seq [group (any |> rep1 |> shortest); str ": "; group (any |> rep1)]
    |> whole_string
    |> compile in
  Re.replace pattern ~f:begin fun groups ->
    let open Ansi_colors in
    Printf.sprintf
      "%s: %s"
      (bold_magenta @@ groups ^. 1)
      (magenta @@ groups ^. 2)
  end

let main () =
  Eio_main.run @@ fun env ->
  let open Eio in
  Switch.run @@ fun sw ->
  let mode = ref `Normal in
  let errin, errout =
    Process.pipe ~sw
    (Stdenv.process_mgr env)
  and stoin, stoout =
    Process.pipe ~sw
    (Stdenv.process_mgr env) in
  let handle line =
    match !mode with
  | `Normal -> Flow.copy_string (line ^ "\n") (Stdenv.stdout env)
  | `Traceback ->
    let fmt =
      let open Containers.Fun in
      prettify_file_location
      %> prettify_exception_msg in
    Flow.copy_string
      (fmt line ^ "\n")
      (Stdenv.stderr env) in
  ( Fiber.fork_daemon ~sw @@ fun () ->
    let flow = Buf_read.of_flow
      ~max_size:1_000_000 errin in
    while true; do
      let line = Buf_read.line flow in
      if Re.execp traceback line
      then mode := `Traceback;
      handle line
    done;
    `Stop_daemon
  );
  ( Fiber.fork_daemon ~sw @@ fun () ->
    let flow = Buf_read.of_flow
      ~max_size:1_000_000 stoin in
    while true; do
      let line = Buf_read.line flow in
      if Re.execp traceback line
      then mode := `Traceback;
      handle line
    done;
    `Stop_daemon
  );
  ( Fiber.fork ~sw @@ fun () ->
    Backend.run
      (Stdenv.process_mgr env)
      ~stdout:stoout
      ~stderr:errout
      (Sys.argv |> Array.to_list |> List.tl)
  )

let () =
  try main ()
  with Backend.Internal_failure x -> exit x
