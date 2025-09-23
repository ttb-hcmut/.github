open Eio

let with_open_in ~vardir ?name:session_name f =
  let session_name = match session_name with
    | Some x -> x
    | None   ->
      let random =
        Random.State.make_self_init () in
      Uuidm.v4_gen random ()
      |> Uuidm.to_string in
  let dir = Path.(vardir / "fs_socket" / session_name) in
  Path.mkdirs ~exists_ok:true ~perm:0o700 dir;
  let _vardir = vardir and _session_name = session_name in
  let open Socket in
  f { vardir = _vardir; session_name = _session_name }
  |> fun return_value ->
  Path.rmtree dir;
  return_value
