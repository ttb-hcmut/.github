let with_make ~vardir session_name f =
  let open Eio in
  let dir = Path.(vardir / "fs_socket" / session_name) in
  Path.mkdirs ~exists_ok:true ~perm:0o700 dir;
  f ~vardir ~session_name
  |> fun return_value ->
  Path.rmtree dir;
  return_value
