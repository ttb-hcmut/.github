module type INPUT = sig
  type t [@@deriving json]
  val function_name : t -> string
  val module_name : t -> string
  val cwd : t -> string
end

module type RESULT = sig
  type t [@@deriving json]

  val return_value : t -> string
  (** [return_value result] gets the return value of a result response.
      
      @return The raw / serialization of a computed Python value.

      @see '/bin/main.ml' Based on the protocol from clientside. *)
end

type env =
  < stderr      : [ `Flow | `Unix_fd | `W ] Eio.Resource.t
  ; domain_name : string
  ; verbose     : bool
  ; process_mgr : [`Unix | `Generic] Eio.Process.mgr_ty Eio.Resource.t
  ; fs          : Eio.Fs.dir_ty Eio.Path.t
  ; err         : Eio_format.formatter option
  >

module type RPC = sig
  module Input : INPUT
  module Result : RESULT
  val eval :
    Input.t ->
    env:env ->
    Result.t
end
