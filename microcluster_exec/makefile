.PHONY:test

build:
	dune build

run:
	@echo "warning: OCaml dynamic linking will not work when running program in this mode"
	dune exec microcluster_exec

install:
	opam install ./

test:
	dune test

clean:
	dune clean
