#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "jq" jq  --version
check "curl" curl  --version
check "git" git  --version
check "zsh" zsh --version
check "ps" ps --version
check "Oh My Zsh! theme" test -e $HOME/.oh-my-zsh/custom/themes/devcontainers.zsh-theme
check "zsh theme symlink" test -e $HOME/.oh-my-zsh/custom/themes/codespaces.zsh-theme
check "zsh theme filename" test -e $HOME/.oh-my-zsh/custom/themes/codespaces.zsh-theme
check "oh-my-zsh executes" zsh -c 'source $HOME/.zshrc && echo $0 | grep zsh'

# Report result
reportResults