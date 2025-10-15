open Eio
let (!) xref = Stream.take xref
let (!|) xref = Stream.add xref None
let (+=) xref x = Stream.add xref (Some x)
