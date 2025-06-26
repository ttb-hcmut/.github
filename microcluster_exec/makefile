.PHONY:test

build:
	dune build

run:
	@echo "warning: OCaml dynamic linking will not work when running program in this mode"
	dune exec microcluster_exec

install:
	dune exec opam install .

test:
	dune test

doc:
	dune build @doc

clean:
	dune clean
