#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "ruby version 3.1.2 installed as default" ruby -v | grep 3.1.2
check "ruby version 2.5.9 installed"  rvm list | grep 2.5.9
check "ruby version 3.0.4 installed"  rvm list | grep 3.0.4

check "rbenv" bash -c 'eval "$(rbenv init -)" && rbenv --version'
check "rake" bash -c "gem list | grep rake"

# Report result
reportResults
