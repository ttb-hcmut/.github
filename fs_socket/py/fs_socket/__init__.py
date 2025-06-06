import aio_os
import aiofile

class FsSocket():
  def __init__(self, file, onclose):
    self.file = file
    self.onclose = onclose

  async def close(self):
    await self.file.close()
    await self.onclose(self)

async def open(session, name):
  filename = f"/var/fs_socket/{session}/{name}"
  await aio_os.mkfifo(filename)
  file = await aiofiles.open(filename, "rw")
  async def onclose(_):
    await aiofiles.unlink(filename)
  fs_socket = FsSocket(file, onclose)
  return fs_socket
