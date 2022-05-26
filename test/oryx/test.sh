#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

echo $PATH
check "Oryx version" oryx --version
check "ORYX_SDK_STORAGE_BASE_URL" $ORYX_SDK_STORAGE_BASE_URL
check "ENABLE_DYNAMIC_INSTALL" $ENABLE_DYNAMIC_INSTALL

# Report result
reportResults