#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Always run these checks as the non-root user
user="$(whoami)"
check "user" grep vscode <<< "$user"

# Check for an installation of Isort
check "version_isort" isort --version

# Check for an installation of Poetry
check "version_poetry" poetry --version

# Check for an installation of Sphinx
check "version_sphinx" sphinx-build --version

# Report result
reportResults
