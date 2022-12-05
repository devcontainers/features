#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Always run these checks as the non-root user
user="$(whoami)"
check "user" grep vscode <<<"$user"

# Check for an installation of JupyterLab
check "version" jupyter lab --version

# Check location of JupyterLab installation
packages="$(python3 -m pip list)"
check "location" grep jupyter <<<"$packages"

# Check for git extension
check "jupyterlab-git" grep jupyterlab-git <<<"$packages"

# Check for nbdime extension
check "nbdime" grep nbdime <<<"$packages"

# Check for correct JupyterLab configuration
check "config" grep ".*.allow_origin = '*'" /home/vscode/.jupyter/jupyter_server_config.py

# Report result
reportResults
