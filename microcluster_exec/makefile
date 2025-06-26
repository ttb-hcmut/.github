.PHONY:test

build:
	dune build

run:
	@echo "warning: OCaml dynamic linking will not work when running program in this mode"
	dune exec microcluster_exec

install:
	opam install ./ --deps-only && opam reinstall --working-dir ./

test:
	dune test

doc:
	dune build @doc

clean:
	dune clean
