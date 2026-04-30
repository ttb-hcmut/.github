{ pkgs ? import <nixpkgs> {} }:

let
  # Build a Python interpreter with required packages preloaded
  pythonEnv = pkgs.python311.withPackages (ps: with ps; [
    numpy
    aiofile
    pip
    setuptools
    hatchling
  ]);
in
pkgs.mkShell {
  buildInputs = with pkgs; [
    vscode
    dune_3
    opam
    ocaml
    gcc
    gnumake

    pythonEnv

    mpremote
    micropython
    esptool
    arduino-cli
    platformio
  ];

  shellHook = ''
    export LD_LIBRARY_PATH=${pkgs.gcc.cc.lib}/lib:$LD_LIBRARY_PATH

    # Add microcluster_exec/bin to PATH if it exists
    if [ -d "$PWD/microcluster_exec/bin" ]; then
      export PATH="$PWD/microcluster_exec/bin:$PATH"
    fi

    # Initialize opam if not already done
    if [ ! -d "$HOME/.opam" ]; then
      echo "Initializing opam..."
      opam init --bare --disable-sandboxing --yes
    fi

    # Always load opam env
    eval $(opam env)

    # Override Python to make sure subprocesses (e.g., in microcluster_exec) use this one
    export PATH=${pythonEnv}/bin:$PATH

    echo "Dev environment ready!"
  '';
}

