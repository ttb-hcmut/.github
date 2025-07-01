.PHONY:test

build:
	dune build

init:
	opam pin add .

run:
	dune exec microcluster_exec

install:
	dune build && opam install .

test:
	dune test

clean:
	dune clean
