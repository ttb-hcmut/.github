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

let inplace_transform_file ~fs ~process_mgr file f =
  let open Eio in
  Process.parse_out process_mgr Buf_read.line ["mktemp"]
  |> fun s -> Path.(fs / s)
  |> fun tmpfile ->
  begin
    Path.load file
    |> Path.save ~create:`Never tmpfile
  end;
  f tmpfile

let remove_microcluster_canvas =
  let pattern =
    let open Re in
    seq
    [ any |> rep
    ; alt [ str "parallel"; str "microcluster_canvas" ]
    ; any |> rep
    ]
    |> compile in
  fun s ->
  Re.replace ~all:true ~f:(fun _ -> "") pattern s

module A = struct
  let to_string x = x
end

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
    let cache, resolve_cache = Promise.create () in
    [%with_report "detected task {A}"]
    begin fun () ->
      Hashtbl.add trn_cachemap request.module_name (cache, ((), request.function_name));
      request.module_name
    end |> ignore;
    inplace_transform_file ~process_mgr ~fs Path.(fs / request.cwd / (request.module_name ^ ".py"))
      begin fun file ->
        let text = 
          file
          |> Path.load in
        let text =
          text
          |> String.split_on_char '\n'
          |> List.map remove_microcluster_canvas
          |> String.concat "\n" in
        Path.save ~create:(`Or_truncate 0x600) file text;
        file
      end
    |> fun file ->
    Mpremote.copy ~process_mgr ~null:(fun ~sw -> Path.open_out ~create:`Never ~sw Path.(fs / "/dev/null"))
      ~from:(`local begin
        Fpath.of_string (Path.native_exn file)
        |> Result.get_ok
      end)
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
