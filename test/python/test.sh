#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "version" python --version

# Tests for optional arguments
# check "jupyterlab" jupyter lab --version
# check "jupyterlab-config" grep 'allow_origin' /home/vscode/.jupyter/jupyter_notebook_config.py
# check "ml-packages" /usr/local/python/current/bin/python -c 'import numpy'

# Report result
reportResults
