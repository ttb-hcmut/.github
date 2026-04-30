open Microcluster_exec

let with_open_in ~cwd ~namespace f =
  let open Eio in
  let dir = Path.(cwd / namespace) in
  Path.mkdirs ~exists_ok:false ~perm:0o700 dir;
  f dir |> fun ret ->
  Path.rmtree dir;
  ret

type 'a backend =
  { process_mgr : 'a Eio.Process.mgr
  ; command : Command.t
  ; cwd     : Eio.Fs.dir_ty Eio.Path.t
  }

let backend process_mgr command cwd =
  { process_mgr; command; cwd }

module type Clientside = sig
  include Fs_socket__client.D
  module Fs_socket : sig
    val fetch : string expr -> dict expr -> ?name:(string expr) -> unit -> dict expr awaitable
  end
end

(** A callback [f = fun self -> ...] is an [_ intercept] which is a callback
    definition that will be executed in the remote runtime. *)
module type Interceptor = functor (C : Clientside) -> sig
  open C
  val v : func:(unknown list -> dict -> unit) ref -> unit -> unknown stmt
end
[@@alert experimental
  "The clientside interceptor pattern is being evaluated."]

module Z (CUser : Clientside) = struct open CUser let f (module Lo : Interceptor) =
  let module X = Fs_socket__client.X(CUser) in
  X.f >>=
  let* parallel_decorator_factory = def0 () ~kwargs:object method all_ = [] end @@ fun () ~kwargs:_ ->
    let* parallel = def1 () ~kwargs:object method all_ = [] end @@ fun func ~kwargs:_ ->
      let* wrapper = def_varargs @@ fun args kwargs ->
        let+ os = import (module Os) in
        let module Os = Os.M(val os) in
        if_ (is (Os.getenv @@ string "MICROCLUSTER_ENV") none) begin fun () ->
          let func = mkfunc_varargs func in
          let open Spreading in
          return @@ func (( * ) !args) (( ** ) !kwargs)
        end >>=
        let* asynctemp = async_def0 () @@ fun () ->
          let module Lo = Lo(CUser) in
          Lo.v ~func () in
        let asynctemp = mkfunc1 asynctemp in
        return @@ asynctemp unit in
      return !wrapper in
    return !parallel in
  let* _parallel = ref ~name:"parallel" @@ !parallel_decorator_factory in
  ignore_ unit
end

let backend_run ~backend (module Y : Interceptor) =
  let module State = struct let state__indent = ref 0 end in
  let open Offshoring in
  let module AUser = struct
    include Python (State)
    include PythonLiteral
    include PythonExt
    include PythonStd (State)
    module Uuid = struct
      let spec = { namespace = "uuid" }
      module M (I : LibEnv) = struct
        type uuid = string
        let uuid4 () = I.libs.namespace ^ ".uuid4()"
        let to_string x = "str(" ^ x ^ ")"
      end
    end
    module Fs_socket = struct
      let fetch session info ?name () = "comm(" ^ ([session; info] @ (match name with None -> [] | Some name -> ["name=(" ^ name ^ ")"]) |> String.concat ", ") ^ ")"
    end
  end in
  let module Z = Z(AUser) in
  let python_content = Z.f (module Y) in
  with_open_in ~cwd:backend.cwd ~namespace:"_microcluster" @@ fun space ->
    let filename = Eio.Path.(space / "microcluster_canvas.py") in
    Eio.Path.save ~create:(`Exclusive 0o666) filename python_content;
    let env =
      Unix.environment ()
      |> Array.append
        [| Printf.sprintf
            {|MICROCLUSTER_ENV=%s|} "run"
        ;  Printf.sprintf
            {|PYTHONPATH=%s|} (Sys.getenv "PYTHONPATH" ^ ":" ^ Eio.Path.native_exn space)
        |] in
    Eio.Process.run backend.process_mgr ~env
      (Command.unparse backend.command)

module Response = struct
  type t = { return_value: string }
  [@@deriving fields ~getters]

  let make return_value = { return_value }

  let jsont =
    let open Jsont in
    Object.map make
    |> Object.mem
      "return_value" string
      ~enc:return_value
    |> Object.finish
end

module Request = struct
  type t =
    { module_name: string
    ; function_name: string
    ; cwd: string
    }
  [@@deriving fields ~getters]

  let make module_name function_name cwd =
    { module_name; function_name; cwd }

  let jsont =
    let open Jsont in
    Object.map make
    |> Object.mem
      "module_name" string
      ~enc:module_name
    |> Object.mem
      "function_name" string
      ~enc:function_name
    |> Object.mem
      "cwd" string
      ~enc:cwd
    |> Object.finish
end

let _'remove_microcluster_canvas (ast: PyreAst.Concrete.Module.t) =
  let open PyreAst.Concrete in
  let body = ast.body |> List.fold_left (fun acc x -> match x with
    | Statement.ImportFrom { names; location; module_ = Some module_; level } when String.equal (Identifier.to_string module_) "microcluster_canvas" ->
      let names = names |> List.filter (
        let open ImportAlias in
        function
        | { name; _ } when String.equal (Identifier.to_string name) "parallel" -> false
        | _ -> true
      ) in
      ( match names with
      | [] -> acc
      | _ ->
        let x = Statement.make_importfrom_of_t ~location ~names ~module_ ~level () in
        x :: acc
      )
    | Statement.Import { names; location } ->
      let names = names |> List.filter (
        let open ImportAlias in
        function
        | { name; _ } when String.equal (Identifier.to_string name) "microcluster_canvas" -> false
        | _ -> true
      ) in
      ( match names with
      | [] -> acc
      | _ ->
        let x = Statement.make_import_of_t ~location ~names () in
        x :: acc
      )
    | Statement.AsyncFunctionDef { decorator_list; location; name; args; body; returns; type_comment; type_params } ->
      let decorator_list = decorator_list |> List.filter (
        (* this decorator expression must be fully evaluated so that we know its absolute id. For name, match name *)
        function
        | Expression.Call { func = Expression.Name { id; _ }; _ } when String.equal (Identifier.to_string id) "parallel" -> false
        | Expression.Call { func = Attribute { value = Expression.Name { id = receiver; _ }; attr = id ; _ }; _ } when String.equal (Identifier.to_string receiver) "microcluster_canvas" && String.equal (Identifier.to_string id) "parallel" -> false
        | _ -> true
      ) in
      let x = Statement.make_asyncfunctiondef_of_t ~decorator_list ~location ~name ~args ~body ?returns ?type_comment ~type_params () in
      x :: acc
    | _ -> x :: acc
  ) []
  and type_ignores = ast.type_ignores
  in
  let body = List.rev body in
  Module.make_t ~body ~type_ignores ()
  |> Result.ok

let _'rpc'eval env request =
  let open Eio in
  let open Request in
  let process_mgr = Stdenv.process_mgr env
  and fs = Stdenv.fs env in
  Path.(fs / request.cwd / (request.module_name ^ ".py"))
  |> File_transform.map ~process_mgr ~fs begin fun text ->
    let open Result.Syntax in
    let open PyreAst.Parser in
    with_context @@ fun context ->
    Result.with_ok ~onfail:
      begin function
      | { Error.message ; line ; column ; _ } ->
        let message =
          Printf.sprintf "Python parsing error at line %d, column %d: %s"
            line column message in
        failwith message end @@ fun () ->
    Concrete.parse_module ~context text
    >>= _'remove_microcluster_canvas
    >>= Opine.unparse_py_module
  end
  |> begin fun file ->
    Mpremote.copy ~process_mgr ~null:(fun ~sw -> Path.open_out ~create:`Never ~sw Path.(fs / "/dev/null"))
      ~from:
        (`local
          (Fpath.v (Path.native_exn file)))
      ~dest:(`remote (`mpy, Fpath.(v (request.module_name ^ ".py") )))
  end;
  let conn () =
    Mpremote.Commands.parse_out ~process_mgr Mpremote.Command.
      [ Exec (Printf.sprintf "import %s" request.module_name)
      ; Exec (Printf.sprintf "import asyncio")
      ; Eval (Printf.sprintf "asyncio.run(%s.%s())" request.module_name request.function_name)
      ] in
  conn

let _'rpc'eval =
  let open Eio in
  let trn_cachemap = Hashtbl.create 10 in
  let mutex = Mutex.create () in
  fun request ~env ->
  Switch.run @@ fun sw ->
  let open Request in
  ( Mutex.use_rw ~protect:true mutex @@ fun () ->
    match Hashtbl.find trn_cachemap request.module_name with
  | cached_trn, ((), cached_funname) ->
    if not (String.equal cached_funname request.function_name)
    then failwith {|each module must have only ONE function export|};
    cached_trn
  | exception Not_found ->
    let { module_name; _ } = request in
    [%report0 "detected task <name>{module_name}</name>"];
    ( Fiber.fork_promise ~sw @@ fun () ->
      _'rpc'eval env request
    ) |> fun cache_trn ->
    Hashtbl.add trn_cachemap module_name (cache_trn, ((), request.function_name));
    cache_trn
  )
  |> Promise.await_exn
  |> fun fn -> fn ()
  |> Response.make

module Micropython_default_rpc : Controller.RPC = struct
  module Input = Request
  module Result = Response
  let eval = _'rpc'eval
end

module Controller_make = struct
  let dynamic x : (module Controller.RPC) =
    match x with
  | _ -> failwith ("the device driver <name>" ^ x ^ "</name> is not supported")
end

open Eio

let main command
~device:_ ~device_driver ~verbose =
  Eio_main.run @@ fun env ->
  let env = object
    method cwd = env#cwd
    method fs = env#fs
    method process_mgr = env#process_mgr

    method domain_name = Microcluster_exec.Lib.domain_name
    method verbose = verbose
    method stderr  = env#stderr
    method err = Some (Format.eio__err_formatter env)
  end in
  ( [%with_report {|detected program language <enum>{Language}</enum>|}] @@ fun () ->
    Detect_language.parse command ~cwd:(Stdenv.cwd env)
    |> function
    | `LanguageOCaml  -> failwith "OCaml is not supported yet"
    | `LanguagePython as x -> x
  ) |> ignore;
  let module Rpc =
    ( val
      match device_driver with
      | "generic_micropython" -> (module Micropython_default_rpc)
      | x -> Controller_make.dynamic x
      : Controller.RPC ) in
  [%report0 "computer info:\n  nodes:\n    <name>{device_driver}</name>\n    <prepos>total</prepos> <number>1</number>"];
  let vardir  = Path.
    ( Stdenv.fs env
      / Sys.getenv "HOME"
      / ".var" ) in
  Fs_socket.Namespace.with_open_in ~vardir @@ fun socket ->
  Switch.run @@ fun sw ->
  ( Fiber.fork_daemon ~sw @@ fun () ->
    let module Fs = Fs_socket in
    socket |> Fs.Namespace_watch.iter
      ~process_mgr:(Stdenv.process_mgr env)
      ~i:(module Rpc.Input)
      ~o:(module Rpc.Result)
      begin fun x ->
      Fs.Socket.reply x @@ fun inp ->
      let env = (env :> Controller.env) in
      Rpc.eval inp ~env
      end
    |> ignore;
    `Stop_daemon
  );
  ( Fiber.fork ~sw @@ fun () ->
    let backend = backend
      (Stdenv.process_mgr env)
      command (Stdenv.cwd env) in
    backend_run ~backend
      begin fun%functor (module C : Clientside) ~func () ->
      let module Server__fs_socket = Fs_socket in
      let open C in
      let s_ = string in
      let+ ast = import (module Ast) in
      let module Ast = Ast.M(val ast) in
      let+ os = import (module Os) in
      let module Os = Os.M(val os) in
      let* resp = ref @@ await @@
        let func = Function.v2 !func in
        Fs_socket.fetch (s_ (Server__fs_socket.Socket.session_name socket)) (Dict.of_assoc__single_t [string "function_name", Function.r__name__ func; string "module_name", Function.r__module__ func; string "cwd", Os.getcwd ()]) () in
      let* lol = ref @@ Dict.(!. !resp (s_ "return_value") ) in
      let- lol = assert__isinstance lol klass__string in
      let* xx = ref @@ Ast.literal_eval !lol in
      return !xx
      end
  )

open Cmdliner

let main =
  Cmd.v
  ( Cmd.info Microcluster_exec.Lib.domain_name
    ~doc:
    " A Python / OCaml interpreter that dissects your program and
    orchestrates distributable tasks to a micro-cluster. "
  ) @@
  let open Term.Syntax in
  let+ device =
    Arg.
    ( value
    & opt string "/dev/ttyACM0"
    & info ["F"; "file"]
      ~doc:
      " Open and use the specific $(docv). "
      ~docv:"DEVICE"
    )
  and+ device_driver =
    Arg.
    ( value
    & opt string "generic_micropython"
    & info ["D"; "device-driver"]
      ~doc:
      " Use the specific $(docv). "
      ~docv:"DEVICE_DRIVER"
    )
  and+ command =
    Arg.
    ( value
    & pos_all string []
    & info []
      ~doc:
      " Command for executing the program script. "
      ~docv:"COMMAND"
    )
  and+ verbose =
    Arg.
    ( value
    & flag
    & info ["verbose"]
      ~doc:
      " Increases the level of verbosity of diagnostic messages printed on
      standard error. "
      ~docv:"VERBOSE"
    ) in
  let command =
    command
    |> Command.parse_opt
    |> Option.unwrap
      ~error_msg:
      " command should not be empty " in
  main
    ~device ~device_driver ~verbose
    command

let () =
  if !Sys.interactive then () else
  Cmd.eval
    ~err:Format.err_formatter
    main
  |> exit
