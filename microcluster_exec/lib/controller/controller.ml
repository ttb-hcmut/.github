module type Input = sig
  type t [@@deriving json]
end

module type Result = sig
  type t [@@deriving json]

  val return_value : t -> string
  (** [return_value result] gets the return value which is the raw /
      serialization of a computed Python value.

      @see The protocol from clientside as written in [/bin/main.ml] *)
end

type env =
  < stderr      : [ `Flow | `Unix_fd | `W ] Eio.Resource.t
  ; domain_name : string
  ; verbose     : bool
  ; process_mgr : [`Unix | `Generic] Eio.Process.mgr_ty Eio.Resource.t
  ; fs          : Eio.Fs.dir_ty Eio.Path.t
  ; err         : Eio_format.formatter option
  >

module type Rpc = sig
  module Input : Input
  module Result : Result
  val fold_left :
    Input.t ->
    env:env ->
    Result.t
end

let p : (module Rpc) option ref = ref None

