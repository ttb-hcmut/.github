let mutex = Eio.Mutex.create ()

let copy ~from ~dest ~null =
  let open Scp_types in
  let from = file_to_string from
  and dest = file_to_string dest in
  let open Eio in
  fun ~process_mgr ->
  Switch.run @@ fun sw ->
  let null = null ~sw in
  Mutex.use_ro mutex @@ fun () ->
  Process.run process_mgr ~stdout:null
  [ "mpremote"
  ; "cp"
  ; from
  ; dest
  ]

type remote_file = [`mpy] Scp_types.remote_file_raw

let run (file: remote_file) =
  let `remote (`mpy, file) = file in
  let file = Fpath.to_string file in
  let open Eio in
  fun ~process_mgr ->
  Mutex.use_ro mutex @@ fun () ->
  Process.parse_out
    process_mgr
    Eio.Buf_read.line
    [ "mpremote"
    ; "run"
    ; file
    ]

module Command = struct
  type t =
    | Exec of string
    | Eval of string

  let to_string_parts t = match t with
    | Exec s -> ["exec"; s]
    | Eval s -> ["eval"; s]
end

module Commands = struct
  let run cmds ~process_mgr =
    let open Eio in
    Mutex.use_ro mutex @@ fun () ->
    Process.run process_mgr
      begin
        [ "mpremote" ]
        @ (cmds |> List.map Command.to_string_parts |> List.flatten)
      end

  let parse_out cmds ~process_mgr =
    let open Eio in
    try
    Mutex.use_ro mutex @@ fun () ->
    Process.parse_out process_mgr Buf_read.line
      begin
        [ "mpremote" ]
        @ (cmds |> List.map Command.to_string_parts |> List.flatten)
      end
    with Failure s -> failwith ("an error occurred when running mpremote: " ^ s)
end
