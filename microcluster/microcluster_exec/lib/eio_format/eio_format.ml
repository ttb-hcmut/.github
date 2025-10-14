type formatter =
  { out_function : string -> unit
  }

let fprint formatter s =
  s
  |> formatter.out_function

let eprint ~stderr s =
  s
  |> fun s -> Eio.Flow.copy_string s stderr

let make_formatter out =
  { out_function = out }
