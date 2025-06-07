type runner =
  [ `Python
  | `Utop
  ]

let runner_to_string (x: runner) = match x with
  | `Python -> "python"
  | `Utop   -> "utop"

let runner_parse_opt = function
  | "python"
  | "py"
  | "python3" -> Some `Python
  | "utop" -> Some `Utop
  | _ -> None

type t =
  { runner : runner option
  ; program_file : string
  ; arguments : string list
  }

let make runner program_file arguments =
  { runner; program_file; arguments }

let parse_opt = function
  | [] -> None
  | [head] ->
    Option.some @@
    ( match runner_parse_opt head with
    | Some _ -> failwith "missing program file input"
    | None   -> make None head []
    )
  | (head :: mid :: body) ->
    Option.some @@
    match runner_parse_opt head with
    | Some _ as x -> make x mid body
    | None        -> make None head (mid :: body)

let unparse (x: t) =
  let args =
    match x.runner with
    | Some x -> [runner_to_string x]
    | None -> [] in
  args @ [x.program_file] @ x.arguments
