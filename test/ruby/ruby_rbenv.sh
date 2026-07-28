#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# rbenv (and its shims/bin dirs) is placed on PATH via containerEnv,
# so these commands should work in non-login shells too.
check "ruby version 3.4.2 active" bash -c "ruby -v | grep 3.4.2"
check "rbenv available" rbenv --version
check "rbenv lists ruby 3.4.2" bash -c "rbenv versions | grep 3.4.2"
check "rbenv global is 3.4.2" bash -c "rbenv global | grep 3.4.2"
check "rbenv shim for ruby" test -x /usr/local/share/rbenv/shims/ruby
check "ruby-build wired as rbenv plugin" test -d /usr/local/share/rbenv/plugins/ruby-build
check "rake gem installed" bash -c "gem list | grep rake"

# Report result
reportResults
