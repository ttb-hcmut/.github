# Road to v0.9

> Working prototype (without the design icks)

- [ ] Migrate logic from microcluster_canvas to microcluster_exec. Code as data
- [ ] ensure colorful output, like nix (highlight names, separation between semantic and symbolic markup, modify cmdliner?)
- [x] object type for capability-passing
- [x] logging for external module (domain_err), log for ports/micropython
- [ ] object type deriving (so `Controller.env` can derive from `Log_domain.domain_err`)
- [ ] jsont serializable deriving
- [x] ppx-based logging
- [ ] (cont. of Dynlink) dynamic module system
- [ ] install ComplexArts/micropython-numpy
- [ ] manip code by ast (`remove_microcluster_canvas`)
- [ ] cancel mutex of mpremote
- [ ] passing argument RPC
- [ ] script to build and install mpy modules

Functional changes:
- [ ] option to choose rpc controller
- [ ] error message from mpy execution, propagate remote exception to mainland
- [x] verbose mode toggle

Documentation
- [ ] linear regression example
- [ ] Document modules and functions
- [ ] Activity diagram for fs_socket
- [ ] A motion canvas video illustrates the pipeline
- [ ] A typst cetz paper illustrates the pipeline, activity diagram
