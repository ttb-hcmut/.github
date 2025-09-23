type t =
  [ `LanguagePython
  | `LanguageOCaml
  ]

let to_string (x: t) = match x with
  | `LanguagePython -> "python"
  | `LanguageOCaml  -> "ocaml"

let of_extension_opt : string -> t option = function
  | ".py" -> Some `LanguagePython
  | ".ml" -> Some `LanguageOCaml
  | _     -> None
