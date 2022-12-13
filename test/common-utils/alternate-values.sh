#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "jq" jq  --version
check "curl" curl  --version
check "git" git  --version
check "ps" ps --version
check "no zsh" bash -c '! zsh --version'
check "No Oh My Zsh!" test ! -e $HOME/.oh-my-zsh/custom/themes/devcontainers.zsh-theme

# Report result
reportResults