(* TODO: deriving serializable *)

module type Input = sig
  type t
  val jsont: t Jsont.t
end

module type Result = sig
  type t
  val jsont: t Jsont.t
end

module type Rpc = sig
  module Input : Input
  module Result : Result
  val fold_left :
    Input.t ->
    process_mgr: [`Unix | `Generic] Eio.Process.mgr_ty Eio.Resource.t ->
    fs: Eio.Fs.dir_ty Eio.Path.t ->
    Result.t
end

let p : (module Rpc) option ref = ref None

