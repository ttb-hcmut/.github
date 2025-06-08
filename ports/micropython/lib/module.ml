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

let fold_left =
  let open Eio in
  let trn_cachemap = Hashtbl.create 10 in
  fun request ->
  let open Request in
  ( match Hashtbl.find trn_cachemap request.module_name with
  | cached_trn, ((), cached_funname) ->
    if not (String.equal cached_funname request.function_name)
    then failwith "each module must have only ONE function export";
    Promise.await cached_trn
  | exception Not_found ->
    let cache, resolve_cache = Promise.create () in
    Hashtbl.add trn_cachemap request.module_name (cache, ((), request.function_name));
    let conn () = 1 in
    Promise.resolve resolve_cache conn;
    conn
  )
  |> fun f -> f ()
  |> Response.make

module Rpc : Controller.Rpc = struct
  module Input = Request
  module Result = Response
  let fold_left = fold_left
end

let () =
  Controller.p := Some (module Rpc : Controller.Rpc)
