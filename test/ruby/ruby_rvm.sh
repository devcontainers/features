#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Ruby installed via rvm lives under /usr/local/rvm/rubies and is also
# exposed via the /usr/local/rubies/current PATH entry from containerEnv.
check "ruby version 3.4.2 active" bash -c "ruby -v | grep 3.4.2"
check "rvm binary available" /usr/local/rvm/bin/rvm --version
check "rvm ruby 3.4.2 directory exists" test -d /usr/local/rvm/rubies/ruby-3.4.2
# rvm is implemented as a shell function, so source it before calling.
check "rvm default points to 3.4.2" bash -c "source /usr/local/rvm/scripts/rvm && rvm current | grep 3.4.2"
check "rvm profile.d hook installed" test -x /etc/profile.d/rvm.sh
check "rake gem installed" bash -c "gem list | grep rake"

# Report result
reportResults
