#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "version" jupyter lab --version
check "config" grep 'allow_origin' /home/vscode/.jupyter/jupyter_notebook_config.py

# Report result
reportResults
