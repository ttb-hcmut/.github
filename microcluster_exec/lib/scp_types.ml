type path = Fpath.t

type 'origin file_any =
  [ `local of path
  | `remote of 'origin * path
  ]

type remote =
  [ `mpy ]

let remote_to_string (t: remote) = match t with
  | `mpy -> ":"

type file = remote file_any

let file_to_string (f: file) = match f with
  | `local s -> Fpath.to_string s
  | `remote (u, s) -> (remote_to_string u) ^ ":" ^ (Fpath.to_string s)
