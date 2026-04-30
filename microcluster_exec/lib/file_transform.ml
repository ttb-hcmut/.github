let _mktemp ~fs ~process_mgr f =
  let open Eio in
  Process.parse_out process_mgr Buf_read.line ["mktemp"]
  |> Path.(/) fs
  |> f

(** [file |> map ~fs ~process_mgr @@ fun text -> ...] *)
let map ~fs ~process_mgr f file =
  let open Eio in
  _mktemp ~fs ~process_mgr @@ fun tmpfile ->
  Path.load file
  |> f
  |> Path.save ~create:`Never tmpfile;
  tmpfile
