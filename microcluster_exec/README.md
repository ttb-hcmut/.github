## Develop

Build Dependencies:
- dune
- GNU Make (optional)

Runtime Dependencies:
- mpremote

### Build

```sh
cd microcluster_exec

make
# or
make build
# or
dune build
```

### Install

```sh
cd microcluster_exec

make install
# or
opam install ./
```

### Run

Assume you've installed:

```
$ microcluster_exec 
usage: microcluster_exec [-hv] -F PORT FILENAME
```

Refer manual / documentation for more information.

### Test

```sh
cd microcluster_exec

make test
# or
dune test
```
