open Eio

let with_promise f =
  let promise, resolver = Promise.create () in
  f promise
  |> Promise.resolve resolver
