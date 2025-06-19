type rules = Re.(t * (Group.t -> string option))

type 'formatter formatter = 
  ?rules:rules ->
  unit ->
  'formatter

module Syntax = Syntax
