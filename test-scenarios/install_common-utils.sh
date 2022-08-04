#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "user" whoami | grep devcontainer
check "zsh" zsh --version
check "wget" wget -V

# Report result
reportResults
