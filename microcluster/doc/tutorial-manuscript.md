# Setup Instructions for microcluster (big_matrix example)

### 🛠️ If files fail to run:
```sh
nix-shell -p python311 python311Packages.numpy python311Packages.aiofile gcc
```

---

### 📦 Set up Python virtual environment
```sh
cd ~/Project/microcluster/examples/big_matrix
python3 -m venv venv
source venv/bin/activate
```

---

### 📥 Install required Python modules
```sh
cd ~/Project/microcluster/microcluster_exec/fs_socket/py
pip install -e .

cd ~/Project/microcluster/microcluster_canvas
pip install -e .
```

---

### 📜 Install Python dependencies for the example
```sh
cd ~/Project/microcluster/examples/big_matrix
pip install -r requirements.txt
```

---

### ▶️ Run the example
```sh
python main.py
```

---

### 🧱 Build and test OCaml code
```sh
cd ~/Project/microcluster/microcluster_exec

# Create empty local opam switch
opam switch create . --empty

# Pin and install fs_socket library
opam pin add fs_socket ./fs_socket/ml
opam install fs_socket

# If nix didn't set OPAM env properly
eval $(opam env)

# Install dependencies and build
opam install .
make -C microcluster_exec
make -C microcluster_exec install

# Optional: run tests (⚠️ may not be complete/stable)
make -C microcluster_exec test
```

---

### 🏃 Run microcluster_exec
```sh
export PATH="$PWD/microcluster_exec/bin:$PATH"

# Example test
microcluster_exec --verbose python example.py

# Run full example
microcluster_exec --verbose python ./examples/big_matrix/main.py
```

> ⚠️ Note: nixpkgs sometimes interferes with Python environments — using a `venv` is safer for now.
