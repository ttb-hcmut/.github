val err_formatter :
  Stdlib.Format.formatter Styled_format.formatter
;;

val cmdliner__err_formatter : Styled_format.rules

open Eio

val eio__err_formatter :
  < stderr : [> Flow.sink_ty ] Resource.t ; .. > ->
  Eio_format.formatter Styled_format.formatter
