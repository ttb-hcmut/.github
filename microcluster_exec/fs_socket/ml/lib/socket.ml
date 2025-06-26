type t =
  { vardir : Eio.Fs.dir_ty Eio.Path.t
  ; session_name : string
  }
[@@deriving fields ~getters]
