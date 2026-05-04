Microcluster has the capability to generate Python code on-demand, and more importantly in this subject, generate Python type definitions.

We require that programs that run under Microcluster need to use the `@microcluster.parallel()` decorator, or `@parallel` for short, as marker for the interpreter. The definition of `@parallel` is guaranteed to be generated when running. However, writers of Python also uses static type-checkers during development which needs type annotations and type sheds to function properly. Code generation is therefore not enough.

In this case, we distribute the necessary type shed under the PIP package `microcluster.canvas`. Additionally, the user can choose to generate type shed on-demand as a feature of Microcluster_exec.
