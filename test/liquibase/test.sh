#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "liquibase" liquibase --version

# Report result
reportResults