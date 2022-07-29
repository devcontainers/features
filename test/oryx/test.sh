#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "Oryx version" oryx --version
check "Dotnet version" dotnet --version
check "ORYX_SDK_STORAGE_BASE_URL" echo $ORYX_SDK_STORAGE_BASE_URL
check "ENABLE_DYNAMIC_INSTALL" echo $ENABLE_DYNAMIC_INSTALL

# Report result
reportResults