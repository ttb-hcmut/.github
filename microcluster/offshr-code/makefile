.PHONY:test

build:
	dune build

init:
	make -C fs_socket/ml init
	opam pin add .

run:
	@echo "warning: OCaml dynamic linking will not work when running program in this mode"
	dune exec microcluster_exec

install:
	dune build && opam install .

test:
	dune test

clean:
	dune clean

