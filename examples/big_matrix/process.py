import numpy as np
from microcluster_canvas import parallel

@parallel()
async def process():
  a = np.random.rand(3, 3)
  for _ in range(1000):
    b = np.random.rand(3, 3) * 10
    c = np.random.rand(3, 3) * 10
    for _ in range(100):
      b = np.cross(b, c)
    a += b
  return a
