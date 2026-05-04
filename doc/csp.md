**Cross-stage persistence** (or **CSP** for short) is an umbrella term for phenomena relating to when values and references are passed or shared between distinct computing environments. For example, when a `@parallel` async function is called, argument values from the Python world must be serialized, or hashed, then get passed to the MicroPython world, then gets demarshalled by mpremote's eval command.The reverse happens when the MicroPython function finished running and returns value which must be deserialized by the Python world through `ast.literal_eval`. In this case, CSP refers to the hashing techniques and preprocessing steps to ensure that the Python semantics remain valid despite being executed across distinct Python runtimes.

Currently, like the JAX engine before this, we assume that each `@parralel` function is pure. Even then, argument passing is nontrivial.

- How can we guarantee float precision?
- How do we serialize non-primitive values / complex objects?
- How can we pass higher-order functions? How can we pass lambdas?
- Can we cache some serialization?

Beyond this, is it possible to implement a kind of closure system for global variables? Indeed, it is Python's semantics.
