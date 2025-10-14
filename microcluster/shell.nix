{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  name = "microcluster-shell";

  nativeBuildInputs = with pkgs; [
    dune_3
    ocaml
    opam
    mpremote
    gnumake
    python3
    python3Packages.virtualenv
    python3Packages.pip
  ];

  shellHook = ''
    echo "Setting up opam local switch if missing..."
    if [ ! -d "./_opam" ]; then
      opam init --bare --disable-sandboxing --yes
      opam switch create . --empty
      eval $(opam env)
      make -C microcluster_exec init
      make -C microcluster_exec install
      make -C microcluster_exec build
      make -C microcluster_exec test
    else
      eval $(opam env)
    fi

    echo "Setting up Python virtualenv..."
    cd microcluster_canvas
    if [ ! -d venv ]; then
      python3 -m venv venv
    fi
    source venv/bin/activate

    echo "Installing microcluster_canvas in editable mode..."
    pip install --upgrade pip setuptools wheel
    pip install -e .
    cd ..
  '';
}

