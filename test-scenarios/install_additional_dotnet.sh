#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "dotnet version 6.0.301 installed as default" dotnet --version | grep 6.0.301
check "dotnet version 5.0 installed"  ls -l /usr/local/dotnet | grep 5.0
check "dotnet version 3.1.420 installed"  ls -l /usr/local/dotnet | grep 3.1.420

# Report result
reportResults