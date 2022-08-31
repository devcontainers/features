#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "Oryx version" oryx --version
check "Dotnet is not removed if it is not installed by the Oryx Feature" dotnet --version

# Report result
reportResults
