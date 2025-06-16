type 'a domain_err = 'a constraint 'a =
  < stderr      : _ Eio.Flow.sink
  ; domain_name : string
  ; verbose     : bool
  ; ..
  > as 'a

let with_report ~env:(domain_err:'a domain_err) ~msg f =
  let value = f () in
  if domain_err#verbose
  then Eio.Flow.copy_string (domain_err#domain_name ^ ": " ^ (msg value) ^ "\n") (Eio.Stdenv.stderr domain_err);
  value
