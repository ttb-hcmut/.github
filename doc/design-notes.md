## Formatter

In XXXX, we introduced formatters, a preprocessing stage to add colors to stderr output.

1. We use formatters that can be combined.

2. We use formatters that can be one-way combined by extending with additional rules (current)

Exibit 1 is ideal. However, there's currently no formatter implementation in the OCaml ecosystem that allows combination [^redirect].

Exibit 2 is adopted by the current system. This is implemented by the `Microcluster_exec.Format` formatters. These are extended versions of `Stdlib.Format` formatters in that they allow you to specify addition _styling rules_. By this system, the default Microcluster_exec semantics are implemented by `Microcluster_exec.Format.<private>translate`, while the modifications to the Cmdliner recolors are implemented by `Microcluster_exec.Format.Cmdliner.Re.styles`. So, this method works. The issue is that there's a hierarchy between the default semantics and the Cmdliner recolors, where the former is prioritized / first applied. Furthermore, this styling rule system adds complexity to the preprocessing function.

[^redirect]: It's possible to redirect the output _channel_ of one formatter to a different channel. But how to apply this idea to different formatters is still unsolved.
