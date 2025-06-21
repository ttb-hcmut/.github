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

def get_uclustr_env():
  import os
  import json
  uclustr_env = os.getenv("MICROCLUSTER_ENV")
  try:
    uclustr_env = json.loads(uclustr_env)
  except (json.decoder.JSONDecodeError, TypeError):
    return None
  return uclustr_env

program = get_uclustr_env()
stm = RIOCServer()

import ast
import fs_socket
import os

def _parallel_decorator_factory(*arg):
  def parallel(func):
    def wrapper(*args, **kwargs):
      if program is None:
        return func(*args, **kwargs)
      vars = {}
      vars['self'] = func
      return stm.eval(program, vars=vars)
    return wrapper
  return parallel

parallel = _parallel_decorator_factory
