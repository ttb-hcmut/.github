module type D = sig
  include Offshr_code__py.Cde_withstd.S
  module Uuid : sig
    val spec : spec
    module M (_ : LibEnv) : sig
      type uuid
      val uuid4 : unit -> uuid expr
      val to_string : uuid expr -> string expr
    end
  end
end

module X (C : D) = struct let f =
  let open C in
  let+ asyncio = import (module Asyncio) in
  let module Asyncio = Asyncio.M(val asyncio) in
  let* mkfifo = async_def1 () ~kwargs:object method all_ = [] end
    begin fun filename ~kwargs:_ -> 
    let* proc = ref @@ await (Asyncio.create_subprocess_shell (string "mkfifo '" ^+ !filename ^+ string "'") ~stdout:Asyncio.Subprocess.pipe ~stderr:Asyncio.Subprocess.pipe ()) in
    let** _, stderr = ref2 ~names:("_", "stderr") @@ await (Asyncio.Subprocess.communicate !proc ()) in
    if_ (Asyncio.Subprocess.returncode !proc != number_of_int 0) begin fun () ->
      raise_ @@ exception_ !stderr
    end
    end in
  let mkfifo = mkasyncfunc1 mkfifo in
  let* unlink = async_def1 () ~kwargs:object method all_ = [] end
    begin fun filename ~kwargs:_ -> 
    let* proc = ref @@ await (Asyncio.create_subprocess_shell (string "rm '" ^+ !filename ^+ string "'") ~stdout:Asyncio.Subprocess.pipe ~stderr:Asyncio.Subprocess.pipe ()) in
    let** _, stderr = ref2 ~names:("_", "stderr") @@ await (Asyncio.Subprocess.communicate !proc ()) in
    if_ (Asyncio.Subprocess.returncode !proc != number_of_int 0) begin fun () ->
      raise_ @@ exception_ !stderr
    end
    end in
  let unlink = mkasyncfunc1 unlink in
  let+ json = import (module Json) in
  let module Json = Json.M(val json) in
  let+ os = import (module Os) in
  let module Os = Os.M(val os) in
  let+ uuid = import (module Uuid) in
  let module Uuid = Uuid.M(val uuid) in
  let* comm_proc = async_def2 () ~kwargs:object method all_ = ["name", ()] end
    begin fun session info ~kwargs:_ -> 
    let* kwargs__name = ref @@ string "" in
    let* filename = ref @@ Os.getenv (string "HOME") ^+ string "/.var/fs_socket/" ^+ !session ^+ string "/" ^+ (if__ (is !(kwargs__name) none) ~then_:(string "") ~else_:(!(kwargs__name) ^+ string "-")) ^+ Uuid.(uuid4 () |> to_string) in
    ignore_ (await (mkfifo !filename)) >>=
    let* text = ref (Json.dumps !info) in
    let* reply = ref (string "") in
    if_ (bool true) begin fun () ->
      let* proc = ref @@ await (Asyncio.create_subprocess_shell (string "echo '" ^+ !text ^+ string "' > '" ^+ !filename ^+ string "'") ~stdout:Asyncio.Subprocess.pipe ~stderr:Asyncio.Subprocess.pipe ()) in
      let** _, stderr = ref2 ~names:("_", "stderr") @@ await (Asyncio.Subprocess.communicate !proc ()) in
      if_ (Bool.of_number @@ Asyncio.Subprocess.returncode !proc) begin fun () ->
        raise_ @@ exception_ !stderr
      end
    end >>=
    if_ (bool true) begin fun () ->
      let* proc = ref @@ await (Asyncio.create_subprocess_shell (string "cat '" ^+ !filename ^+ string "'") ~stdout:Asyncio.Subprocess.pipe ~stderr:Asyncio.Subprocess.pipe ()) in
      let** stdout, stderr = ref2 ~names:("stdout", "stderr") @@ await (Asyncio.Subprocess.communicate !proc ()) in
      if_ (Bool.of_number @@ Asyncio.Subprocess.returncode !proc) begin fun () ->
        raise_ @@ exception_ !stderr
      end >>=
      (reply := !stdout)
    end >>=
    let* reply = ref @@ Json.loads !reply in
    ignore_ (await (unlink !filename)) >>=
    return !reply
  end in
  let* __comm = ref ~name:"comm" !comm_proc in
  ignore_ unit
end
