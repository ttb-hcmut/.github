let copy =
  let open Scp_types in
  fun ~from ~dest ->
  let from = file_to_string from
  and dest = file_to_string dest in
  let open Eio in
  fun ~process_mgr ->
  Process.run process_mgr
  [ "mpremote"
  ; "cp"
  ; from
  ; dest
  ]
