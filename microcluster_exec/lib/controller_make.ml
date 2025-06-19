open Controller

let load_module name : (module Rpc) =
  Dynlink.adapt_filename name |> fun name ->
  if Sys.file_exists name
  then begin
    try Dynlink.loadfile name; Option.get !Controller.p
    with
    | (Dynlink.Error e) as err -> Eio.traceln "error when loading dynamic module: %s" (Dynlink.error_message e); raise err
    | (Invalid_argument s) as err -> Eio.traceln "error when loading dynamic module: %s" s; raise err
    | _ -> failwith "unknown dynamic module error"
  end else failwith "dynamic module file does not exist"

let getenv s =
  try Sys.getenv s
  with Not_found -> failwith "Have you initialized all MICROCLUSTER_* environmental variables?"

let of_id x = match x with
  | "micropython" -> load_module ((getenv "MICROCLUSTER_PROJECT_ROOT") ^ "/ports/micropython/module.cmxs")
  | _             -> failwith ""
