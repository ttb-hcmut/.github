import fs_socket.aio_os
import asyncio
import json
import os
import aiofile
import uuid

# NOTE(kinten): Works, but is obviously not efficient
async def _comm_proc(session, info, *args, name=None):
  filename = f"{os.getenv("HOME")}/.var/fs_socket/{session}/{"" if name is None else (name + "-")}{uuid.uuid4()}"
  await aio_os.mkfifo(filename)
  text = json.dumps(info)
  if True:
    proc = await asyncio.create_subprocess_shell(f"echo '{text}' > '{filename}'", stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE)
    _, stderr = await proc.communicate()
    if proc.returncode != 0:
      raise Exception(stderr)
  if True:
    proc = await asyncio.create_subprocess_shell(f"cat '{filename}'", stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE)
    stdout, stderr = await proc.communicate()
    if proc.returncode != 0:
      raise Exception(stderr)
    reply = stdout
  reply = json.loads(reply)
  await aio_os.unlink(filename)
  return reply

comm = _comm_proc
