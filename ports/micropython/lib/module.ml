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

let remove_microcluster_canvas =
  let pattern =
    let open Re in
    seq
    [ any |> rep
    ; alt [ str "parallel"; str "microcluster_canvas" ]
    ; any |> rep
    ]
    |> compile in
  Re.replace
    ~all:true
    ~f:(fun _ -> "")
    pattern

let fold_left =
  let open Eio in
  let trn_cachemap = Hashtbl.create 10 in
  fun request ~env ->
  let process_mgr = Stdenv.process_mgr env
  and fs = Stdenv.fs env in
  let open Request in
  ( match Hashtbl.find trn_cachemap request.module_name with
  | cached_trn, ((), cached_funname) ->
    if not (String.equal cached_funname request.function_name)
    then failwith {|each module must have only ONE function export|};
    Promise.await cached_trn
  | exception Not_found ->
    let cache, resolve_cache = Promise.create ()
    and { module_name; _ }   = request in
    [%report0 "detected task {module_name}"];
    Hashtbl.add trn_cachemap module_name (cache, ((), request.function_name));
    inplace_transform_file ~process_mgr ~fs Path.(fs / request.cwd / (request.module_name ^ ".py"))
      begin fun text -> text
        |> String.split_on_char '\n'
        |> List.map remove_microcluster_canvas
        |> String.concat "\n"
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
    Promise.resolve resolve_cache conn;
    conn
  )
  |> fun f -> f ()
  |> Response.make

module Rpc = struct
  module Input = Request
  module Result = Response
  let fold_left = fold_left
end

let () =
  Controller.p := Some (module Rpc : Controller.Rpc)
