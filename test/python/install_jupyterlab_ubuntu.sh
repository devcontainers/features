#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Check for an installation of JupyterLab
check "version" jupyter lab --version

# Check location of JupyterLab installation
packages="$(python3 -m pip list)"
check "location" grep jupyter <<< "$packages"

# Check for git extension
check "jupyterlab_git" grep jupyterlab_git <<< "$packages"

# Check for correct JupyterLab configuration
check "config" grep ".*.allow_origin = '*'" /root/.jupyter/jupyter_server_config.py

# Report result
reportResults
