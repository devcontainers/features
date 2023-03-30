#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "ruby" ruby -v
check "rake" bash -c "gem list | grep rake"

# Report result
reportResults
