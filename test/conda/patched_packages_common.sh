#!/bin/bash

# Inspect cleanup before running Conda or importing packages can recreate caches.
cache_python=(/opt/conda/bin/python3 -B -)
if [ "$(id -u)" -ne 0 ]; then
    cache_python=(sudo -n "${cache_python[@]}")
fi
check "installation caches removed" "${cache_python[@]}" "$HOME" <<'PY'
import sys
from pathlib import Path

from packaging.version import Version

conda_dir = Path("/opt/conda")
leftovers = list(conda_dir.rglob("*.pyc"))
leftovers.extend(conda_dir.rglob("__pycache__"))
for package in (conda_dir / "pkgs").glob("pip-[0-9]*"):
    version = package.name.removeprefix("pip-").split("-", 1)[0]
    if Version(version) < Version("26.1"):
        leftovers.append(package)
for cache in (
    conda_dir / "pkgs/cache",
    Path("/root/.cache/pip"),
    Path(sys.argv[1]) / ".cache/pip",
):
    if cache.exists():
        leftovers.append(cache)
assert not leftovers, f"Installation cache leftovers: {leftovers}"
PY

check "patched packages installed in base environment" env PYTHONNOUSERSITE=1 /opt/conda/bin/python3 -B - <<'PY'
import json
import sys
from importlib.metadata import version
from pathlib import Path

from packaging.version import Version

assert sys.prefix == "/opt/conda", f"Unexpected Python prefix: {sys.prefix}"
packages = {}
for metadata in Path("/opt/conda/conda-meta").glob("*.json"):
    package = json.loads(metadata.read_text())
    packages[package["name"]] = package["version"]

for name, expected in {
    "cryptography": "50.0.0",
    "pyopenssl": "26.4.0",
    "openssl": "3.5.8",
    "brotli": "1.2.0",
}.items():
    actual = packages.get(name)
    assert actual == expected, f"{name}: expected {expected}, got {actual}"

assert Version(version("pip")) >= Version("26.1"), f"Unpatched pip: {version('pip')}"
assert version("python-dotenv") == "1.2.2", f"Unexpected python-dotenv: {version('python-dotenv')}"
PY

check "base environment writable by runtime user" test -w /opt/conda/conda-meta
check "conda still works" conda --version
check "pip still works" /opt/conda/bin/python3 -m pip --version
