.PHONY:test

build:
	dune build

init:
	opam pin add .

run:
	dune exec mpremote

install:
	dune build && opam install .

test:
	dune test

clean:
	dune clean
