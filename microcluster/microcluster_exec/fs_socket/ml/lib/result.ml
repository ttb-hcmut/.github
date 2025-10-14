include Stdlib.Result

let get_ok = function
  | Ok x -> x
  | Error s -> failwith s
