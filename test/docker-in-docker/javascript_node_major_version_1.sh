#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

./test.sh

# Report result
reportResults