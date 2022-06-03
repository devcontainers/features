#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "version" python --version

# python -m pip show jupyterlab
# check "jupyterlab" jupyter lab --version

# cat /home/vscode/.jupyter/jupyter_notebook_config.py
# check "jupyterlab-config" grep 'allow_origin' /home/vscode/.jupyter/jupyter_notebook_config.py

# Report result
reportResults
