import asyncio.coroutines as c
import fs_socket
import json
import inspect
import os
import uuid

class FunctionTask():
  def __init__(self, func):
    self.func = func
    self.name = f"{self.func.__name__}-{uuid.uuid4()}"

  def __str__(self):
    return json.dumps(self.to_dict())

  def to_dict(self):
    info = { 'module_name': self.func.__module__, 'function_name': self.func.__name__, 'cwd': os.getcwd() }
    return info

def get_uclustr_env():
  uclustr_env = os.getenv("MICROCLUSTER_ENV")
  try:
    uclustr_env = json.loads(uclustr_env)
  except json.decoder.JSONDecodeError:
    return None
  try:
    session_name = uclustr_env["session_name"]
  except KeyError:
    return None
  return uclustr_env

env = get_uclustr_env()

def _parallel_decorator_factory(*arg):
  def parallel(func):
    def wrapper(*args, **kwargs):
      if env is None:
        return func(*args, **kwargs)
      task = FunctionTask(func)
      async def work():
        reply = await fs_socket.comm(env['session_name'], task.name, task.to_dict())
        retval = reply['return_value']
        return retval
      return work()
    return wrapper
  return parallel

parallel = _parallel_decorator_factory
