import asyncio.coroutines as c
import json
import inspect
import os

is_uclustr_env = json.loads(os.getenv("MICROCLUSTER_ENV"))

class FunctionTask():
  def __init__(self, func):
    self.func = func

  def __str__(self):
    info = { 'language': 'python', 'module_name': self.func.__module__, 'function_name': self.func.__name__, 'cwd': os.getcwd() }
    return json.dumps(info)

def _parallel_decorator_factory(*arg):
  def parallel(func):
    def wrapper(*args, **kwargs):
      print(is_uclustr_env)
      task = FunctionTask(func)
      print(task)
      promise = task.func(*args, **kwargs)
      return promise
    return wrapper
  return parallel

parallel = _parallel_decorator_factory
