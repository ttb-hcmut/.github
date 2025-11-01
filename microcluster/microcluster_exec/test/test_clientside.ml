open Microcluster_exec
open Offshoring

module Backend = struct
  module type E = sig
    include Fs_socket__client.D
    module Fs_socket : sig
      val fetch : string expr -> dict expr -> ?name:(string expr) -> unit -> dict expr awaitable
    end
  end

  module type Interceptor = functor (C : E) -> sig
    open C
    val f : func:(unknown list -> dict -> unit) ref -> unit -> dict stmt
  end

  module Z (CUser : E) = struct open CUser let f (module Lo : Interceptor) =
    let module X = Fs_socket__client.X(CUser) in
    X.f >>=
    let* parallel_decorator_factory = def0 () ~kwargs:object method all_ = [] end @@ fun () ~kwargs:_ ->
      let* parallel = def1 () ~kwargs:object method all_ = [] end @@ fun func ~kwargs:_ ->
        let* wrapper = def_varargs @@ fun args kwargs ->
          let+ os = import (module Os) in
          let module Os = Os.M(val os) in
          if_ (is (Os.getenv @@ string "MICROCLUSTER_ENV") none) begin fun () ->
            let func = mkfunc_varargs func in
            let open Spreading in
            return @@ func (( * ) !args) (( ** ) !kwargs)
          end >>=
          let* asynctemp = async_def0 () @@ fun () ->
            let module Lo = Lo(CUser) in
            Lo.f ~func () in
          let asynctemp = mkfunc1 asynctemp in
          return @@ asynctemp unit in
        return !wrapper in
      return !parallel in
    let* _parallel = ref ~name:"parallel" @@ !parallel_decorator_factory in
    ignore_ unit
  end

  let provide (module Y : Interceptor) =
    let module State = struct let state__indent = ref 0 end in
    let module AUser = struct
      include Python (State)
      include PythonLiteral
      include PythonExt
      include PythonStd (State)
      module Uuid = struct
        let spec = { namespace = "uuid" }
        module M (I : LibEnv) = struct
          type uuid = string
          let uuid4 () = I.libs.namespace ^ ".uuid4()"
          let to_string x = "str(" ^ x ^ ")"
        end
      end
      module Fs_socket = struct
        let fetch session info ?name () = "comm(" ^ ([session; info] @ (match name with None -> [] | Some name -> ["name=(" ^ name ^ ")"]) |> String.concat ", ") ^ ")"
      end
    end in
    let module Z = Z(AUser) in
    let text = Z.f (module Y) in
    (* print_endline text; *)
    text |> Alcotest.(check string) "lol"
{|import asyncio as a
async def b(c):
  d = await (a.create_subprocess_shell(("mkfifo '") + ((c) + ("'")), stdout=a.subprocess.PIPE, stderr=a.subprocess.PIPE))
  _, stderr = await (d.communicate())
  if d.returncode != 0:
    raise Exception(stderr)

async def e(f):
  g = await (a.create_subprocess_shell(("rm '") + ((f) + ("'")), stdout=a.subprocess.PIPE, stderr=a.subprocess.PIPE))
  _, stderr = await (g.communicate())
  if g.returncode != 0:
    raise Exception(stderr)

import json as h
import os as i
import uuid as j
async def k(l, m, *__args, name=None):
  n = ""
  o = (i.getenv("HOME")) + (("/.var/fs_socket/") + ((l) + (("/") + (("" if n is None else (n) + ("-")) + (str(j.uuid4()))))))
  await (b(o))
  p = h.dumps(m)
  q = ""
  if True:
    t = await (a.create_subprocess_shell(("echo '") + ((p) + (("' > '") + ((o) + ("'")))), stdout=a.subprocess.PIPE, stderr=a.subprocess.PIPE))
    _, stderr = await (t.communicate())
    if bool(t.returncode):
      raise Exception(stderr)
  if True:
    s = await (a.create_subprocess_shell(("cat '") + ((o) + ("'")), stdout=a.subprocess.PIPE, stderr=a.subprocess.PIPE))
    stdout, stderr = await (s.communicate())
    if bool(s.returncode):
      raise Exception(stderr)
    q = stdout
  r = h.loads(q)
  await (e(o))
  return (r)

comm = k

def u():
  def v(w):
    def x(*y, **z):
      import os as za
      if za.getenv("MICROCLUSTER_ENV") is None:
        return (w(*(y), **(z)))
      async def zb():
        import ast as zc
        import os as zd
        ze = await (comm("A76C", { ("function_name"):(w.__name__), ("module_name"):(w.__module__), ("cwd"):(zd.getcwd()) }))
        zf = ze["return_value"]
        assert isinstance(zf, str)
        zg = zc.literal_eval(zf)
        assert isinstance(zg, dict)
        return (zg)

      return (zb())

    return (x)

  return (v)

parallel = u
|}
end

let () =
  let session = "A76C" in
  Backend.provide(module functor (C : Backend.E) -> struct let f ~func () =
    let open C in
    let s_ = string in
    let+ ast = import (module Ast) in
    let module Ast = Ast.M(val ast) in
    let+ os = import (module Os) in
    let module Os = Os.M(val os) in
    let* resp = ref @@ await @@
      let func = Function.v2 !func in
      Fs_socket.fetch (s_ session) (Dict.of_assoc__single_t [string "function_name", Function.r__name__ func; string "module_name", Function.r__module__ func; string "cwd", Os.getcwd ()]) () in
    let* lol = ref @@ Dict.(!. !resp (s_ "return_value") ) in
    let- lol = assert__isinstance lol klass__string in
    let* xx = ref @@ Ast.literal_eval !lol in
    let- xx = assert__isinstance xx klass__dict in
    return !xx
  end);
