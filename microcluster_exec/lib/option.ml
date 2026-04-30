include Stdlib.Option

let unwrap ~error_msg = function
  | Some x -> x
  | None   -> failwith error_msg
