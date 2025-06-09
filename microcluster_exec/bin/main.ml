open Microcluster_exec;;

type 'a backend =
  { process_mgr : 'a Eio.Process.mgr_ty Eio.Resource.t
  ; command: Command.t
  ; session_name: string
  }
let backend process_mgr command session_name = { process_mgr; command; session_name }

let backend_run ~backend =
  let env =
    Unix.environment ()
    |> Array.append
      [| Printf.sprintf {|MICROCLUSTER_ENV={ "session_name": "%s" }|} backend.session_name |]
    in
  Eio.Process.run backend.process_mgr ~env (Command.unparse backend.command)

(* type serial = { path : Eio.Fs.dir_ty Eio.Resource.t * string } *)
(* let serial path = { path } *)

let with_report ~stderr ~domain ~msg f =
  let value = f () in
  Eio.Flow.copy_string (domain ^ ": " ^ (msg value) ^ "\n") stderr;
  value

let with_report = with_report ~domain:"microcluster_exec"

let main ~device command =
  device |> ignore;
  let open Eio in
  Eio_main.run @@ fun env ->
  (* let serial  = serial Path.(Stdenv.fs env / device) *)
  let process_mgr = Stdenv.process_mgr env
  and with_report = with_report ~stderr:(Stdenv.stderr env)
  and vardir  = Path.(Stdenv.fs env / Sys.getenv "HOME" / ".var") in
  let command = match command with Some x -> x | None -> failwith "command is empty" in
  let session_name =
    Uuidm.v4_gen (Random.State.make_self_init ()) ()
    |> Uuidm.to_string in
  let backend = backend
    (Stdenv.process_mgr env)
    command session_name in
  ( with_report ~msg:(fun x -> "detected program language " ^ (Language.to_string x)) @@ fun () ->
    Detect_language.parse command ~cwd:(Stdenv.cwd env)
    |> function
    | `LanguageOCaml  -> failwith "OCaml is not supported yet"
    | `LanguagePython as x -> x
  ) |> ignore;
  let module Rpc = (val Controller_make.of_id "micropython" : Controller.Rpc) in
  Fs_socket.Namespace.with_make ~vardir session_name @@ fun ~vardir ~session_name ->
  Switch.run @@ fun sw ->
  Fs_socket.Namespace_watch.all ~process_mgr ~vardir ~ejsont:Rpc.Result.jsont ~fjsont:Rpc.Input.jsont ~session_name ~sw
  |> function seq, stop_hosting ->
  ( Fiber.fork ~sw @@ fun () ->
    Switch.run @@ fun sw ->
    seq |> Seq.fold_left begin fun _ ctx ->
      Fiber.fork ~sw @@ fun () ->
      Fs_socket.reply ctx @@ fun inp ->
      Rpc.fold_left inp ~fs:(Stdenv.fs env) ~process_mgr
    end ()
    |> ignore
  );
  ( Fiber.fork ~sw @@ fun () ->
    backend_run ~backend;
    stop_hosting ()
  );
  ()

let main =
  let open Cmdliner in
  Cmd.v
  ( Cmd.info "microcluster_exec"
    ~doc:{|A Python / OCaml interpreter that dissects your program and orchestrates distributable tasks to a micro-cluster.|}
  ) @@
  let open Term.Syntax in
  let+ device =
    Arg.
    ( value
    & opt string "/dev/ttyACM0"
    & info ["F"; "file"]
      ~doc:{|Open and use the specific $(docv).|}
      ~docv:"DEVICE"
    )
  and+ command =
    Arg.
    ( value
    & pos_all string []
    & info []
      ~doc:{|Command for executing the program script.|}
      ~docv:"COMMAND"
    )
  in
  let command = Command.parse_opt command in
  main ~device command

let () =
  if !Sys.interactive then () else
  Cmdliner.Cmd.eval main |> exit
