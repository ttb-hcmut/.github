import asyncio.coroutines as c
import ast
import fs_socket
import json
import inspect
import os
import uuid

class RIOCServer():
  """remote inversion-of-control server"""
  async def eval(self, program, *args, vars={}):
    k = None
    for x in program:
      k = eval(x['rhs'], locals=vars)
      if x['rhs_type'] == 'await':
        k = await k
      vars[x['lhs']] = k
    return k

class FunctionTask():
  def __init__(self, func, args):
    self.func = func
    self.args = args
    self.name = f"{self.func.__name__}-{uuid.uuid4()}"

  def __str__(self):
    return json.dumps(self.to_dict())

  def to_dict(self):
    info = {
      'module_name': self.func.__module__,
      'function_name': self.func.__name__,
      'actual_arguments': self.args, 'cwd': os.getcwd()
    }
    return info

def get_uclustr_env():
  uclustr_env = os.getenv("MICROCLUSTER_ENV")
  try:
    uclustr_env = json.loads(uclustr_env)
  except (json.decoder.JSONDecodeError, TypeError):
    return None
  return uclustr_env

program = get_uclustr_env()
stm = RIOCServer()

def _parallel_decorator_factory(*arg):
  def parallel(func):
    def wrapper(*args, **kwargs):
      if program is None:
        return func(*args, **kwargs)
      task = FunctionTask(func, { 'args': args, 'kwargs': kwargs })
      vars = {}
      vars['task'] = task
      return stm.eval(program, vars=vars)
    return wrapper
  return parallel

parallel = _parallel_decorator_factory
