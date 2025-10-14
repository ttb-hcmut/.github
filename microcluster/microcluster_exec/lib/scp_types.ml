type path = Fpath.t

type 'origin remote_file_raw = [ `remote of 'origin * path ]

type 'origin file_any =
  [ `local of path
  | 'origin remote_file_raw
  ]

type remote =
  [ `mpy ]

let remote_to_string (t: remote) = match t with
  | `mpy -> ""

type file = remote file_any

type remote_file = remote remote_file_raw

let file_to_string (f: file) = match f with
  | `local s -> Fpath.to_string s
  | `remote (u, s) -> (remote_to_string u) ^ ":" ^ (Fpath.to_string s)
