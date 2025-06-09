module Script = Script
module Command = Command
module Language = Language

let language_of_runner : Command.runner -> Language.t = function
  | `Python -> `LanguagePython
  | `Utop   -> `LanguageOCaml
