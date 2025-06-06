## Layer 5

Default program

```python
#!/usr/bin/env python3
import numpy

def process_unet_nodek():
    # ...

def main():
    # ...
```

## Layer 4

Parallelize machine-learning program. Translate neural network to pipelines. Expect some kind of structured concurrency (async, thread (?))

File: `process_unet_nodek.py`

```python
import numpy
import microcluster_canvas

@microcluster_canvas.parallel()
async def main():
    # ...
```

File: `main.py`

```python
#!/usr/bin/env python3
from process_unet_nodek import main as process_unet_nodek
import asyncio

async def main():
    await process_unet_nodek()

if __name__ == "__main__":
    async.run(main())
```

## Layer 3

Task distributor

```
$ microcluster_exec -F /dev/ttyACM0 ./main.py
microcluster: detected program language Python
microcluster: detected task process_unet_nodek
microcluster: ack from aggregator at /dev/ttyACM0
microcluster: computer info:
  nodes:
    esp8266_nodemcu
    arduino_uno_r3
    arduino_uno_r3
    esp32_aithinker
    (total 4)
  tasks:
    process_unet_nodek
    map_node
    (total 2)
    
```

## Layer 2

Linear algebra / scientific computing library for MCU computers

- ulab
- ComplexArts/micropython-numpy. translate between this and numpy. translate between this and OCaml Owl

## Layer 1

High-level, interpretative programming on microcontrollers - *MCU computer*.

- MicroPython (mpy)
- MicroUtop (mutop) (OCaml Interpreter) (doesn't exist yet, just an interesting idea)

Need to have:

- Filesystem (needed for sake of symmetry)
- Command evaluation (interpretative programming language (Python, OCaml), remote procedure call (gRPC, jRPC), etc)

## Layer 0

Physical chassis / frame of the computer. So that we can install (bolt-in and wire-up) a cluster of MCU devices -> a cluster computer. 1 aggregator device, and (N - 1) devices. Communicate via i2c (?)
