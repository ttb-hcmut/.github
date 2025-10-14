include Stdlib.Result

let with_ok ~onfail f =
  match f () with
  | Ok x -> x
  | Error k -> onfail k

module Syntax = struct
  let ( >>= ) = bind
  and return  = ok
end
