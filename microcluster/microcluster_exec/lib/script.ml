type t =
  { shebang: string option
  ; text   : string
  }

let make shebang text =
  { shebang; text }

let empty =
  let shebang = None
  and text = "" in
  { shebang; text }

let grab_shebang_opt =
  let regexp_pattern =
    let open Re in
    seq [ str "#!"; group (notnl |> rep) ]
    |> whole_string
    |> compile in
  function s ->
  Re.exec_opt regexp_pattern s
  |> Option.map @@ fun groups ->
    Re.Group.get groups 1

let of_text s =
  s
  |> String.split_on_char '\n'
  |> function
  | [] -> empty
  | (firstline :: ss) as s->
    match grab_shebang_opt firstline with
    | Some shebang -> make (Some shebang) (ss |> String.concat "\n")
    | None -> make None (s |> String.concat "\n")
