#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

extensions_root="${XDG_DATA_HOME:-"${HOME}/.local/share"}/gh/extensions"

check "gh-version" gh --version

check "gh-extension-installed" test -d "${extensions_root}/gh-dash"
check "gh-extension-git-clone-installed" test -f "${extensions_root}/gh-dash/.git/config"
check "gh-extension-installed-2" test -d "${extensions_root}/gh-copilot"
check "gh-extension-git-clone-installed-2" test -f "${extensions_root}/gh-copilot/.git/config"

# Report result
reportResults
