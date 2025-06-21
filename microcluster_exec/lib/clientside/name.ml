type id_state =
  { mutable last : string
  }

let global = { last = "a" }

let increment id_state =
  let init = String.sub id_state.last 0 (String.length id_state.last - 1) in
  let newstr =
  match (String.get id_state.last (String.length id_state.last - 1)) with
  | 'a' -> init ^ "b"
  | 'b' -> init ^ "c"
  | 'c' -> id_state.last ^ "a"
  | _   -> failwith "wt"
  in
  { last = newstr }

let make () =
  let value = global.last
  and new_id_state = increment global in
  global.last <- new_id_state.last;
  value
