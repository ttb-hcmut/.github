let ( <:: ) x acc =
  match x with
  | Some x -> x :: acc
  | None   -> acc

let translate ?rules =
  let match_name, pattern_name =
    let open Re in
    seq [ str "<name>"; group (any |> rep); str "</name>" ]
    |> Re.mark
  and match_enum, pattern_enum =
    let open Re in
    seq [ str "<enum>"; group (any |> rep); str "</enum>" ]
    |> Re.mark
  and rules, handle_rules =
    match rules with
    | Some x -> let a, b = x in (Some a), b
    | None   -> None, fun _ -> None
    in
  let pattern =
    let open Re in
    alt (rules <:: [ pattern_name; pattern_enum ])
    |> compile in
  Re.replace
    ~all:true
    ~f:
      (fun groups ->
        if Re.Mark.test groups match_name
        then begin
        let content = Re.Group.get groups 1 in
        Printf.sprintf "'\x1B[1;35m%s\x1B[0m'" content
        end
        else if Re.Mark.test groups match_enum
        then begin
        let content = Re.Group.get groups 2 in
        Printf.sprintf "\x1B[1;35m«%s»\x1B[0m" content
        end else match handle_rules groups with
        | Some x -> x
        | None   -> failwith "wtf" )
    pattern

let cmdliner__err_formatter =
  let match_error, pattern_error =
    let open Re in
    str "internal error,"
    |> Re.mark in
  let rules =
    let open Re in
    alt [ pattern_error ]
  and handle_rules groups =
    if Re.Mark.test groups match_error
    then Some begin
      "\x1B[1;31minternal error:\x1B[0m"
    end
    else None
    in
  rules, handle_rules

and err_formatter ?rules () =
  let translate = translate ?rules in
  let output_substring oc s start len =
    let s = translate s in
    Stdlib.output_substring oc s start len in
  Stdlib.Format.make_formatter
    (output_substring stderr)
    (fun () -> Stdlib.flush stderr)

and eio__err_formatter env ?rules () =
  let translate = translate ?rules in
  Eio_format.make_formatter
    ( let open Eio in
      fun s ->
      let s = translate s in
      Flow.copy_string s (Stdenv.stderr env) )
