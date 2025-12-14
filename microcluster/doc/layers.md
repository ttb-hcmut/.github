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

Syntax and language for implicit task-based parallelism [^like-regent], use decorator syntax [^like-modal] [^like-parallelaccelerator]

Python / OCaml code generation, transformation, ensure closures [^csp]

File: `process_unet_nodek.py`

```python
import numpy
from accelerators import parallel as parallel

@parallel()
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

## Layer 3.5

Session-based IPC message-broker / socket library for multi-process communication

eDSL for writing "cross-process procedures" [^jfp][^codecomp].

## Layer 3

Distribute tasks to nodes in microcluster

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

[^csp]: we can check out cross-stage persistent values (CSP)

[^like-modal]: Modal is an ML training service where your infrastructure is programmable with Python with lots of decorators! see https://modal.com

[^like-parallelaccelerator]: ParallelAcelerator.jl is a non-intrusive Julian DSL where you can define vector-parallelizable functions by prefixing an `@acc` decorator. see https://julialang.org/blog/2016/03/parallelaccelerator/

[^like-regent]: Possibily like Regent lang, see https://regent-lang.org

[^jfp]: tagless-final style, see https://okmij.org/ftp/tagless-final

[^codecomp]: lightweight components, see https://www.researchgate.net/publication/220941847_Lightweight_and_Generative_Components_I_Source-Level_Components
