val err_formatter :
  Stdlib.Format.formatter
;;

open Eio

val eio__err_formatter :
  < stderr : [> Flow.sink_ty ] Resource.t ; .. > ->
  Eio_format.formatter
