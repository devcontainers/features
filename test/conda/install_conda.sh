#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "conda" conda --version | grep 4.12.0

# Report result
reportResults
