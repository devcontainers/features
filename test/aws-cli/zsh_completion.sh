#!/bin/bash

set -e

# Import test library for `check` command
source dev-container-features-test-lib

# Check that the zsh completion file exists in the correct location
check "zsh completion file installed" test -f /usr/local/share/zsh/site-functions/_aws

# Check that the completion file has the proper zsh completion header
check "zsh completion file has compdef header" grep -q "^#compdef aws" /usr/local/share/zsh/site-functions/_aws

# Actual ZSH completion testing is a pain, so just ignoring it for now.

# Report result
reportResults
