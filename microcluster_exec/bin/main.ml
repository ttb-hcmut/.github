open Microcluster_exec;;

type 'a backend =
  { process_mgr : 'a Eio.Process.mgr
  ; command: Command.t
  }

let backend process_mgr command = { process_mgr; command }

type ('a, 'b) callback = [ `Promise of string * 'a ] -> 'b Clientside.program

type 'imp intercept = ([ `Object ], ('imp, [ `Unknown ]) Clientside.abstract_value) callback
[@@alert experimental "The clientside interceptor pattern being evaluated."]

let backend_run ~backend =
  fun (interceptor: _ intercept) ->
  let env =
    Unix.environment ()
    |> Array.append
      [| Printf.sprintf
          {|MICROCLUSTER_ENV=%s|}
          begin
            let open Clientside_jsont in
            interceptor (`Promise ("task", `Object))
            |> encode_string
          end
      |] in
  Eio.Process.run backend.process_mgr ~env
    (Command.unparse backend.command)

(* type serial = { path : Eio.Fs.dir_ty Eio.Resource.t * string } *)
(* let serial path = { path } *)

module Option0 = struct
  let unwrap ~error_msg x = match x with
    | Some x -> x
    | None   -> failwith error_msg
end

let domain_name = "microcluster_exec"

let main ~device ~verbose command =
  let open Eio in 
  Eio_main.run @@ fun env ->
  let env = object
    method stderr  = Stdenv.stderr env
    method verbose = verbose
    method cwd     = Stdenv.cwd env
    method fs      = Stdenv.fs env
    method process_mgr = Stdenv.process_mgr env
    method domain_name = domain_name
    method err = Some (Format.eio__err_formatter env)
  end in
  let command = Option0.unwrap command ~error_msg:"command is empty" in
  ( [%with_report {|detected program language <enum>{Language}</enum>|}] @@ fun () ->
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
    command in
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
      method verbose = verbose
      method stderr  = Stdenv.stderr env
      method fs      = Stdenv.fs env
      method domain_name = env#domain_name
      method process_mgr = Stdenv.process_mgr env
      method err = env#err
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
    backend_run ~backend begin fun task ->
      let open Clientside in
      let open Syntax in
      let open Clientside_common in
      let* task      = Task.to_dict task
      and* task_name =
        Attr_get.str "name" task in
      Fs_socket.fetch !session_name task_name task
      >>= Dict_get.str "return_value"
      >>= Ast.literal_eval
    end;
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
  and+ verbose =
    Arg.
    ( value
    & flag
    & info ["verbose"]
      ~doc:{|Increases the level of verbosity of diagnostic messages printed on standard error.|}
      ~docv:"VERBOSE"
    ) in
  let command = Command.parse_opt command in
  main ~device ~verbose command

let () =
  if !Sys.interactive then () else
  Cmdliner.Cmd.eval
    ~err:Format.err_formatter
    main
  |> exit
