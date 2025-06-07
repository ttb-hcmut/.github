import fs_socket.aio_os
import asyncio
import json
import os
import aiofile

class FsSocket():
  def __init__(self, filename, onclose):
    self.filename = filename
    self.file = None
    self.onclose = onclose

  async def close(self):
    await self.file.close()
    await self.onclose(self)

  async def refresh(self):
    if self.file is not None:
      await self.file.close()
    file = await aiofile.async_open(self.filename, "a+")
    self.file = file

  async def send(self, info):
    text = json.dumps(info)
    await self.file.write(text)

  async def receive(self):
    text = self.file.read()
    dct  = json.loads(text)
    return dct

async def open(session, name):
  filename = f"{os.getenv("HOME")}/.var/fs_socket/{session}/{name}"
  await aio_os.mkfifo(filename)
  async def onclose(_):
    await aiofile.unlink(filename)
  fs_socket = FsSocket(filename, onclose)
  await fs_socket.refresh()
  return fs_socket

# FIXME(kinten): Why doesn't it work
async def _comm_file(session, name, info):
  socket = await open(session, name)
  await socket.send(info)
  reply = await socket.receive()
  await socket.close()
  return reply

# FIXME(kinten): Why doesn't it work
async def _comm_manual(session, name, info):
  filename = f"{os.getenv("HOME")}/.var/fs_socket/{session}/{name}"
  await aio_os.mkfifo(filename)
  file = await aiofile.async_open(filename, "w")
  text = json.dumps(info)
  await file.write(text)
  await file.close()
  file = await aiofile.async_open(filename, "r")
  reply = await file.read()
  await file.close()
  reply = json.loads(reply)
  await aio_os.unlink(filename)
  return reply

# NOTE(kinten): Works, but is obviously not efficient
async def _comm_proc(session, name, info):
  filename = f"{os.getenv("HOME")}/.var/fs_socket/{session}/{name}"
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
