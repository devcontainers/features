#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "ruby version 3.4.2 installed as default" ruby -v | grep 3.4.2
check "ruby version 3.2.8 installed"  rvm list | grep 3.2.8
check "ruby version 3.3.2 installed"  rvm list | grep 3.3.2

check "rbenv" bash -c 'eval "$(rbenv init -)" && rbenv --version'
check "rake" bash -c "gem list | grep rake"

# Report result
reportResults

