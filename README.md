# Micro-cluster

A suite of tools to distribute your programs to a cluster of micro-controllers, for machine learning and scientific computation.

[Micro-cluster Execute](./microcluster_exec) is a Python / OCaml interpreter that dissects your program and orchestrates distributed tasks with a micro-cluster. It is written in OCaml.

[Micro-cluster Canvas](./microcluster_canvas) is a library for declaring parallelizable functions to be distributed to a micro-cluster. Currently has binding for Python.

[Filesystem Socket](./fs_socket) is a session-based IPC protocol, implemented as a socket library, used by programs in this project. It has binding for Python and OCaml, for client and server-side.

[Ports](./ports) contains drivers for specific microcontrollers and devices, to be loaded by Micro-cluster Execute.
