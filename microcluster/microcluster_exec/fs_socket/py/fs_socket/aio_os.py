import asyncio

async def mkfifo(filename):
  proc = await asyncio.create_subprocess_shell(f"mkfifo '{filename}'", stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE)
  stdout, stderr = await proc.communicate()
  if proc.returncode != 0:
    raise Exception(stderr)

async def unlink(filename):
  proc = await asyncio.create_subprocess_shell(f"rm '{filename}'", stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE)
  stdout, stderr = await proc.communicate()
  if proc.returncode != 0:
    raise Exception(stderr)
