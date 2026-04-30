open Command
open Eio

let parse command ~cwd =
  command
  |> fun c ->
  match c.runner with
  | Some x -> Lib.language_of_runner x
  | None ->
    Filename.extension c.program_file
    |> Language.of_extension_opt
    |> function
    | Some x -> x
    | None   ->
      c.program_file
      |> Path.(/) cwd
      |> Path.load
      |> Script.of_text
      |> (fun x ->
      let (let*) = Option.bind in
      let* shebang = x.shebang in
      match shebang with
      | "/usr/bin/python" -> Some `LanguagePython
      | "/usr/bin/ocaml"  -> Some `LanguageOCaml
      | _                 -> None
      ) 
      |> Option.value ~default:`LanguagePython
