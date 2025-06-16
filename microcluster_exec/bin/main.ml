open Microcluster_exec;;

type 'a backend =
  { process_mgr : 'a Eio.Process.mgr
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

module Option0 = struct
  let unwrap ~error_msg x = match x with
    | Some x -> x
    | None   -> failwith error_msg
end

let domain_name = "microcluster_exec"

let main ~device command =
  let open Eio in 
  Eio_main.run @@ fun env ->
  let env = object
    method stderr  = Stdenv.stderr env
    method cwd     = Stdenv.cwd env
    method fs      = Stdenv.fs env
    method process_mgr = Stdenv.process_mgr env
    method domain_name = domain_name
  end in
  let command = Option0.unwrap command ~error_msg:"command is empty" in
  ( [%with_report {|detected program language {Language}|}] @@ fun () ->
    Detect_language.parse command ~cwd:(Stdenv.cwd env)
    |> function
    | `LanguageOCaml  -> failwith "OCaml is not supported yet"
    | `LanguagePython as x -> x
  ) |> ignore;
  (* let serial  = serial Path.(Stdenv.fs env / device) *)
  device |> ignore;
  let process_mgr = Stdenv.process_mgr env
  and vardir  = Path.(Stdenv.fs env / Sys.getenv "HOME" / ".var")
  and session_name =
    Uuidm.v4_gen (Random.State.make_self_init ()) ()
    |> Uuidm.to_string in
  let backend = backend
    (Stdenv.process_mgr env)
    command session_name in
  let module Rpc = (val Controller_make.of_id "micropython" : Controller.Rpc) in
  Fs_socket.Namespace.with_make ~vardir session_name @@ fun ~vardir ~session_name ->
  Switch.run @@ fun sw ->
  let seq, stop_hosting =
    Fs_socket.Namespace_watch.all
      ~process_mgr ~vardir
      ~ejsont:Rpc.Result.jsont ~fjsont:Rpc.Input.jsont
      ~session_name ~sw in
  ( Fiber.fork ~sw @@ fun () ->
    let env = (object
      method stderr  = Stdenv.stderr env
      method fs      = Stdenv.fs env
      method domain_name = env#domain_name
      method process_mgr = Stdenv.process_mgr env
    end :> Controller.env) in
    Switch.run @@ fun sw ->
    seq |> Seq.fold_left begin fun _ ctx ->
      Fiber.fork ~sw @@ fun () ->
      Fs_socket.reply ctx @@ fun inp ->
      Rpc.fold_left inp ~env
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
  ( Cmd.info domain_name
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
