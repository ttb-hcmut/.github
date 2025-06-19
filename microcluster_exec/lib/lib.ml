let language_of_runner : Command.runner -> Language.t = function
  | `Python -> `LanguagePython
  | `Utop   -> `LanguageOCaml
