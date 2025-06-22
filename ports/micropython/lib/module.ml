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

let fold_left =
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

module Rpc = struct
  module Input = Request
  module Result = Response
  let fold_left = fold_left
end

let () =
  Controller.p := Some (module Rpc : Controller.Rpc)
