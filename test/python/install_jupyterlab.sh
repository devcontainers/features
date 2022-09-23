#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Run these checks as the non-root user
check "user" whoami | grep vscode

# Check for an installation of JupyterLab
check "version" jupyter lab --version

# Check location of JupyterLab installation
# check "location" /usr/local/python/current/bin/python3 -m pip list | grep jupyter

# Check for correct JupyterLab configuration
check "config" grep ".*.allow_origin = '*'" /home/vscode/.jupyter/jupyter_server_config.py

# Report result
reportResults
