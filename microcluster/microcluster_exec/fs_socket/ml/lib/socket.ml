type t =
  { vardir : Eio.Fs.dir_ty Eio.Path.t
  ; session_name : string
  }
[@@deriving fields ~getters]

type ('input, 'output) request =
  { resolve_promise : 'output Eio.Promise.u
  ; input : 'input
  }

let reply =
  fun { resolve_promise ; input } f ->
  f input
  |> Eio.Promise.resolve resolve_promise
