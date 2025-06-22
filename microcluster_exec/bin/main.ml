open Microcluster_exec;;

type 'a backend =
  { process_mgr : 'a Eio.Process.mgr
  ; command: Command.t
  }

let backend process_mgr command = { process_mgr; command }

type ('arg1, 'ret) callback1 = [ `Promise of string * 'arg1 ] -> 'ret Clientside.program

type 'a intercept = ([ `Object ], ('a, [ `Unknown ]) Clientside.abstract_value) callback1
(** A callback [f = fun self -> ...] is an [_ intercept] which is a callback
    definition that will be executed in the remote runtime. *)
[@@alert experimental
  "The clientside interceptor pattern is being evaluated."]

let backend_run ~backend =
  fun (interceptor: _ intercept) ->
  let env =
    Unix.environment ()
    |> Array.append
      [| Printf.sprintf
          {|MICROCLUSTER_ENV=%s|}
          begin
            let open Clientside_jsont in
            interceptor (`Promise ("self", `Object))
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

let controller__input__dict_set_all module_name function_name cwd x =
  let open Clientside in
  let open Syntax in
  let open Clientside_common in
  Dict_set.str "cwd" cwd x
  >>= Dict_set.str
    "function_name" function_name
  >>= Dict_set.str
    "module_name" module_name

module Response = struct
  type t = { return_value: string }
  let make return_value = { return_value }
  let return_value t = t.return_value
  let jsont =
    let open Jsont in
    Object.map make
    |> Object.mem "return_value" Jsont.string ~enc:return_value
    |> Object.finish
end

module Request = struct
  type t =
    { module_name: string
    ; function_name: string
    ; cwd: string
    }
  let make module_name function_name cwd =
    { module_name; function_name; cwd }
  let module_name t = t.module_name
  let function_name t = t.module_name
  let cwd t = t.cwd
  let jsont =
    let open Jsont in
    Object.map make
    |> Object.mem "module_name" Jsont.string ~enc:module_name
    |> Object.mem "function_name" Jsont.string ~enc:function_name
    |> Object.mem "cwd" Jsont.string ~enc:cwd
    |> Object.finish
end

let mktemp ~fs ~process_mgr f =
  let open Eio in
  Process.parse_out process_mgr Buf_read.line ["mktemp"]
  |> Path.(/) fs
  |> f

let inplace_transform_file ~fs ~process_mgr file f =
  let open Eio in
  mktemp ~fs ~process_mgr @@ fun tmpfile ->
  Path.load file
  |> f
  |> Path.save ~create:`Never tmpfile;
  tmpfile

let result_with_ok ~fail f =
  match f () with
  | Result.Ok x -> x
  | Result.Error k -> fail k

let remove_microcluster_canvas (ast: PyreAst.Concrete.Module.t) =
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

let rpc__eval =
  let open Eio in
  let trn_cachemap = Hashtbl.create 10 in
  fun request ~env ~sw ->
  let process_mgr = Stdenv.process_mgr env
  and fs = Stdenv.fs env in
  let open Request in
  ( match Hashtbl.find trn_cachemap request.module_name with
  | cached_trn, ((), cached_funname) ->
    if not (String.equal cached_funname request.function_name)
    then failwith {|each module must have only ONE function export|};
    cached_trn
  | exception Not_found ->
    let cache, resolve_cache = Promise.create ()
    and { module_name; _ }   = request in
    [%report0 "detected task <name>{module_name}</name>"];
    Hashtbl.add trn_cachemap module_name (cache, ((), request.function_name));
    ( Fiber.fork ~sw @@ fun () ->
      inplace_transform_file ~process_mgr ~fs Path.(fs / request.cwd / (request.module_name ^ ".py"))
        begin fun text ->
          let ( >>= ) = Result.bind in
          let open PyreAst.Parser in
          with_context @@ fun context ->
          result_with_ok ~fail:(function
            | { Error.message ; line ; column ; _ } ->
              let message =
                Printf.sprintf "Python parsing error at line %d, column %d: %s"
                  line column message in
              failwith message
          ) @@ fun () ->
          Concrete.parse_module ~context text
          >>= remove_microcluster_canvas
          >>= fun ast ->
          let open Opine in
          Buffer.contents (Unparse.py_module (Unparse.State.default ()) ast).source
          |> Result.ok
        end
      |> fun file ->
      Mpremote.copy ~process_mgr ~null:(fun ~sw -> Path.open_out ~create:`Never ~sw Path.(fs / "/dev/null"))
        ~from:
          (`local
            (Fpath.v (Path.native_exn file)))
        ~dest:(`remote (`mpy, Fpath.(v (request.module_name ^ ".py") )))
      ;
      let conn () =
        Mpremote.Commands.parse_out ~process_mgr Mpremote.Command.
          [ Exec (Printf.sprintf "import %s" request.module_name)
          ; Exec (Printf.sprintf "import asyncio")
          ; Eval (Printf.sprintf "asyncio.run(%s.%s())" request.module_name request.function_name)
          ] in
      Promise.resolve resolve_cache conn
    );
    cache
  )
  |> fun cache ->
  let promise_result, resolve_result = Promise.create () in
  ( Fiber.fork ~sw @@ fun () ->
    Promise.await cache
    |> fun fn -> fn ()
    |> Response.make
    |> Promise.resolve resolve_result
  );
  promise_result

module Micropython_default_rpc : Controller.RPC = struct
  module Input = Request
  module Result = Response
  let eval = rpc__eval
end

module Controller_make = struct
  let of_id x : (module Controller.RPC) = match x with
  | "micropython" -> (module Micropython_default_rpc : Controller.RPC)
  | _ -> failwith ("the device driver <name>" ^ x ^ "</name> is not supported")
end

let main command =
  fun ~device ~device_driver ~verbose ->
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
  let module Rpc = (val Controller_make.of_id device_driver : Controller.RPC) in
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
      let resolve_reply, inp = ctx in
      Rpc.eval inp ~env ~sw |> fun r ->
      Fiber.fork ~sw @@ fun () ->
      Promise.await r
      |> Promise.resolve resolve_reply
    end ()
    |> ignore
  );
  ( Fiber.fork ~sw @@ fun () ->
    backend_run ~backend begin fun self ->
      let open Clientside in
      let open Syntax in
      let open Clientside_common in
      let* func_name =
        Attr_get.str "__name__" self
      and* module_name =
        Attr_get.str "__module__" self
      and* cwd =
        Os.getcwd () in
      ( Dict.init ()
        >>= controller__input__dict_set_all
          module_name func_name cwd )
      >>= Fs_socket.fetch !session_name ~name:func_name
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
  and+ device_driver =
    Arg.
    ( value
    & opt string "micropython"
    & info ["D"; "device-driver"]
      ~doc:{|Use the specific $(docv).|}
      ~docv:"DEVICE_DRIVER"
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
  main
    ~device ~device_driver ~verbose
    command

let () =
  if !Sys.interactive then () else
  Cmdliner.Cmd.eval
    ~err:Format.err_formatter
    main
  |> exit
