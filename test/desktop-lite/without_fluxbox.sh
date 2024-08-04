#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "fluxbox does not exist" bash -c "! ls -la ~/.fluxbox"