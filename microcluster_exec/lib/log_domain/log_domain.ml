module Env = struct
  let verbose env = env#verbose
  let domain_name env = env#domain_name
  let err env = env#err
end

(** [domain_err] is an extension of [stderr] with domain name [domain_name]
    attached. *)
type 'a domain_err = 'a constraint 'a =
  < stderr      : _ Eio.Flow.sink
  ; domain_name : string
  ; verbose     : bool
  ; err         : Eio_format.formatter option (** error message formatter *)
  ; ..
  > as 'a

let _print env =
  match (Env.err env) with
  | None ->
    Eio_format.eprint
      ~stderr:(Eio.Stdenv.stderr env)
  | Some err ->
    Eio_format.fprint err

(** [with_report ~env ~msg f] will run [f] then, once exiting the scope of
    [f], will log a message [msg].

    @param msg The message, in the form of a function ['a -> string] where
    ['a] is the captured return value of [f]. *)
let with_report ~env:(env:_ domain_err) ~msg f =
  let value = f () in
  if Env.verbose env
  then _print env (Printf.sprintf "%s: %s\n" (Env.domain_name env) (msg value));
  value

and report0 ~env:(env:_ domain_err) ~msg =
  if Env.verbose env
  then _print env (Printf.sprintf "%s: %s\n" (Env.domain_name env) msg)
