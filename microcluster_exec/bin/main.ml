open Microcluster_exec;;

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

module Path0 = struct
  let jsont ~fs = 
    let open Jsont in
    of_of_string @@ fun str -> Eio.Path.(fs / str) |> Result.ok
end

module Request = struct
  type t =
    { module_name: string
    ; function_name: string
    ; cwd: Eio.(Fs.dir_ty Path.t)
    }
  let make module_name function_name cwd =
    { module_name; function_name; cwd }
  let module_name t = t.module_name
  let function_name t = t.module_name
  let cwd t = t.cwd
  let jsont ~fs =
    let open Jsont in
    Object.map make
    |> Object.mem "module_name" Jsont.string ~enc:module_name
    |> Object.mem "function_name" Jsont.string ~enc:function_name
    |> Object.mem "cwd" (Path0.jsont ~fs) ~enc:cwd
    |> Object.finish
end

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
  let command = match command with Some x -> x | None -> failwith "command is none??" in
  let session_name =
    Uuidm.v4_gen (Random.State.make_self_init ()) ()
    |> Uuidm.to_string in
  let backend = backend
    (Stdenv.process_mgr env)
    command session_name in
  ( with_report ~msg:(fun x -> "detected program language " ^ (Language.to_string x)) @@ fun () ->
    let open Command in
    command
    |> fun c ->
    Filename.extension c.program_file
    |> Language.of_extension_opt
    |> function
    | Some x -> x
    | None   ->
      c.program_file
      |> Path.(/) (Stdenv.cwd env)
      |> Path.load
      |> Script.of_text
      |> (fun x ->
        let (let*) = Option.bind in
        let* shebang = x.shebang in
        match shebang with
        | "/usr/bin/python" -> Some `LanguagePython
        | "/usr/bin/ocaml"  -> Some `LanguageOCaml
        | _                 -> None
      ) 
      |> Option.value ~default:`LanguagePython
  )
  |> function
  | `LanguageOCaml  -> failwith "OCaml is not supported yet"
  | `LanguagePython ->
  Fs_socket.Namespace.with_make ~vardir session_name @@ fun ~vardir ~session_name ->
  Switch.run @@ fun sw ->
  Fs_socket.Namespace_watch.all ~process_mgr ~vardir ~ejsont:Response.jsont ~fjsont:(Request.jsont ~fs:(Stdenv.fs env)) ~session_name ~sw
  |> function seq, stop_hosting ->
  ( Fiber.fork ~sw @@ fun () ->
    seq |> Seq.iter @@ fun ctx ->
    Fs_socket.reply ctx @@ fun request ->
    let open Request in
    request.module_name |> ignore;
    request.function_name |> ignore;
    request.cwd |> ignore;
    Response.make 1
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
