#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "ruby-build available" ruby-build --version
check "ruby version 3.4.2 installed as default" bash -c "ruby -v | grep 3.4.2"
check "ruby version 3.4.2 prefix present" test -x /usr/local/rubies/3.4.2/bin/ruby
check "ruby version 3.3.2 prefix present" test -x /usr/local/rubies/3.3.2/bin/ruby
check "ruby version 3.2 series installed" bash -c "ls /usr/local/rubies | grep -E '^3\\.2\\.'"
check "rake" bash -c "gem list | grep rake"

# Report result
reportResults
