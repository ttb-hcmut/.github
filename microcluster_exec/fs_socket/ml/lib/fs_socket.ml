module Namespace = Namespace
module Namespace_watch = Namespace_watch

let with_promise = Promise.with_promise

let reply =
  fun (resolve_x, request) f ->
  f request
  |> Eio.Promise.resolve resolve_x
