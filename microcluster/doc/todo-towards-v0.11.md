- [ ] Documentation on writing Microcluster_exec port modules (tutorial, cookbook, reference)
- [x] clientside: `fun%ftor_ize (module C : Python) -> ...` macro. functorize a function with a module argument [^capture]
- [ ] Prune capabilities: reimplement mktemp in pure OCaml for cwd; ...
- [ ] improved monorero build system (opam-monorepo? opam overlays?)
- [ ] formatter: migrate to ppx_regexp for better DX

Documentation:
- [ ] document modules and functions (format, eio_format, clientside) based on Ocamldoc guidelines[^odoc-guidelines]
- [ ] a typst cetz paper: sequence diagram for fs_socket client/servers
- [ ] a motion canvas video illustrates the pipeline
- [ ] a typst cetz paper: ports/micropython program processing pipeline
- [x] a typst cetz paper: activity / sequence diagram for microcluster_exec frontend/backend fibers

[^capture]: you may capture the `Ast_pattern.pexp_function` node in the ast, see https://ocaml-ppx.github.io/ppxlib/ppxlib/Ppxlib/Ast_pattern/index.html#val-pexp_function
[^odoc-guidelines]: see http://ocamlverse.net/content/documentation_guidelines.html
