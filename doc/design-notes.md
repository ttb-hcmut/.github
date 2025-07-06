# Formatter

This section discusses the evolution of the formatter system. The problem is how to preprocess stderr output with styling (such as colors), in a way that is composable and maintains clarity of semantics.

This template is inspired by the formats of [this](https://github.com/ocaml-multicore/eio/blob/main/doc/rationale.md). We use it flexibly to express design tradeoffs.

### Exhibits

1. **Composable formatters** — Formatters can be combined freely.
2. **One-way extensible formatters** — Formatters can be extended with additional rules, but only in a single direction.
3. **Single global formatter** — One formatter is used for all cases.

### Desirable features

1. Formatters can be composed or layered without conflict.
2. Formatters reflect unified semantics across different stderr outputs (e.g. internal output vs. Cmdliner).
3. The system should favor clear semantics and maintainability over premature optimization.

---

### Exhibit 1: Composable formatters

This would be the ideal system: multiple formatters can be composed freely. However, no formatter implementation in the OCaml ecosystem currently supports this fully[^redirect].

**Pros:**

* Clean abstraction
* True separation of concerns
* Maximally flexible

**Cons:**

* Not available in the current ecosystem
* Requires rethinking formatter architecture at a library level

---

### Exhibit 2: One-way extensible formatters (legacy system)

This is the current approach in `Microcluster_exec.Format`. These formatters are extended versions of `Stdlib.Format`, allowing the specification of additional styling rules. In this system:

* Default Microcluster\_exec semantics are implemented by `Microcluster_exec.Format.<private>translate`
* Cmdliner recolors are defined in `Microcluster_exec.Format.Cmdliner.Re.styles`

However, there's a hierarchy: the base formatter's rules take precedence, and extending it introduces complexity.

**Pros:**

* Works in current OCaml formatter model
* Allows reuse of existing formatting infrastructure
* Cmdliner styling integration possible

**Cons:**

* Styling rules introduce complexity
* Default and extended semantics may conflict
* Not truly compositional

---

### Exhibit 3: Single global formatter (current system)

This is the conclusion we arrived at. Initially, this was avoided due to performance concerns: Cmdliner was thought to exclusively handle its own coloring. But we later realized that stderr output should be treated as a single stream — from a user's perspective, there should be no distinction between Cmdliner output and internal output.

Thus, we use a single formatter for everything. The `?err` argument in `Cmdliner.eval` is a customization override, but it should not break the unified semantics.

**Pros:**

* Declarative and unified
* Simplifies reasoning about stderr formatting
* Aesthetic and semantically clean

**Cons:**

* Slight performance overhead
* May limit fine-grained control in special cases

---

### Final Decision

For our system, we use **Exhibit 3: Single global formatter**.

We chose this approach because it has the best declarativeness and clarity. From a high-level programming perspective, performance optimization should happen *beneath* the abstraction, not dictate its shape. Unified stderr output improves the mental model and results in cleaner architecture overall.

[^redirect]: It's possible to redirect the output *channel* of one formatter to a different channel. But how to apply this idea to different formatters is still unsolved.

---

# Clientside Interceptor

This section concerns how the frontend interpreter (`Microcluster_exec`) communicates with the backend interpreter (e.g., Python or UTop). The problem is how to coordinate this communication and control flow without unnecessary coupling or fragmentation.

### Exhibits

1. **Protocol shared between client and server**
2. **Frontend-defined protocol and callbacks (inversion of control)**

### Desirable features

1. Central visibility of communication logic
2. Reasonable performance overhead
3. Maintainable interface between frontend and backend

---

### Exhibit 1: Protocol shared between client and server

This follows the classic client-server model: both frontend and backend adhere to a shared `fs_socket` protocol and `Controller` spec.

**Pros:**

* Simple and well-understood
* Frontend and backend are decoupled
* Lower overhead in protocol translation

**Cons:**

* Protocol logic is split across systems
* Requires a separate overview document to understand the full flow

---

### Exhibit 2: Frontend-defined protocol (current system)

All communication logic is defined in the frontend (OCaml). The backend (Python, UTop) acts only as an executor. This makes the flow visible in one place: `microcluster_exec/bin/main.ml`.

Challenges:

* Potential performance tradeoffs
* Communication callbacks must be expressed in OCaml, then translated to Python AST

To address this, we introduced `Microcluster_exec.Clientside`, a monadic system that represents portable programs with Python AST as the intermediate representation. This enables a clean callback interface, at the cost of extra abstraction layers.

**Pros:**

* Communication flow is explicit and central
* Easier debugging and tracing
* Highly expressive

**Cons:**

* More complex architecture
* Experimental, language-bound translation layer
* Performance not yet fully evaluated

---

### Final Decision

For our system, we use **Exhibit 2: frontend-defined protocol**.

This design improves observability and developer ergonomics, at the cost of some complexity. The monadic `Clientside` abstraction helps mitigate the OCaml-to-Python translation barrier. While marked experimental, this system is aligned with our philosophy of **expression over performance**.[^0]

[^0]: Kinten’s opinion: expressiveness matters more unless performance becomes a blocker.

---

# Microcluster\_exec Architecture

`Microcluster_exec` is a **composite interpreter**, with two layers:

1. A **backend interpreter** (Python, UTop, etc.) which evaluates the user's code
2. A **frontend interpreter** which intercepts backend async tasks and reroutes them for remote evaluation

A simplified execution flow looks like this (written in the Eio ML DSL):

```ocaml
let command = Command.infer Sys.input_file Sys.other_args in
Communication.with_socket_open @@ fun socket ->
Switch.run @@ fun sw ->
( Fiber.fork ~sw @@ fun ->
  Communication.listen socket ~onrequest:begin fun request ->
    Microcluster.Rpc.eval request
    |> serialize
  end
);
( Fiber.fork ~sw @@ fun () ->
  Backend.run command ~ontask:begin fun task ->
    Communication.fetch socket task
    |> Python_ast.eval_value
  end
)
```

This renders as the following sequence diagram:

![Microcluster Execution Flow](./microcluster_exec_sequence.svg)

This modular architecture ensures the code is interpreted correctly:

* The backend interpreter is pluggable (Python or UTop)
* Async tasks are offloaded to the microcluster for remote execution

[^1]: Currently we only support Python and UTop backends(for sane issue tracking), and async tasks must be marked with the `parallel()` decorator to be intercepted correctly.