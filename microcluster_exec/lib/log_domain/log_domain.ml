module Env = struct
  let verbose env = env#verbose
  let domain_name env = env#domain_name
end

(** [domain_err] is an extension of [stderr] with domain name [domain_name]
    attached. *)
type 'a domain_err = 'a constraint 'a =
  < stderr      : _ Eio.Flow.sink
  ; domain_name : string
  ; verbose     : bool
  ; ..
  > as 'a

(** [with_report ~env ~msg f] will run [f] then, once exiting the scope of
    [f], will log a message [msg].

    @param msg The message, in the form of a function ['a -> string] where
    ['a] is the captured return value of [f]. *)
let with_report ~env:(env:_ domain_err) ~msg f =
  let value = f () in
  if Env.verbose env
  then Eio.Flow.copy_string ((Env.domain_name env) ^ ": " ^ (msg value) ^ "\n") (Eio.Stdenv.stderr env);
  value

let report0 ~env:(env:_ domain_err) ~msg =
  if Env.verbose env
  then Eio.Flow.copy_string ((Env.domain_name env) ^ ": " ^ msg ^ "\n") (Eio.Stdenv.stderr env);
