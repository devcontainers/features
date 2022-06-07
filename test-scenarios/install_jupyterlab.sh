#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "jupyterlab" jupyter lab --version
check "jupyterlab-config" grep 'allow_origin' /home/vscode/.jupyter/jupyter_notebook_config.py

# Report result
reportResults
