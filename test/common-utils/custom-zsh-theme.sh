#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "zsh" zsh --version
check "oh-my-zsh installed" test -d $HOME/.oh-my-zsh
check "zsh theme is fino" grep 'ZSH_THEME="fino"' ~/.zshrc
check "default shell is zsh" bash -c "getent passwd $(whoami) | awk -F: '{ print \$7 }' | grep '/bin/zsh'"

# Report result
reportResults
