.PHONY:test

build:
	dune build

init:
	opam pin add .

install:
	dune build && opam install .

test:
	dune test

clean:
	dune clean
