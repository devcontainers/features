#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "Oryx version" oryx --version
check "ORYX_SDK_STORAGE_BASE_URL" echo $ORYX_SDK_STORAGE_BASE_URL
check "ENABLE_DYNAMIC_INSTALL" echo $ENABLE_DYNAMIC_INSTALL

check "oryx-install-nodejs-12.22.11" oryx prep --skip-detection --platforms-and-versions nodejs=12.22.11
check "nodejs-12.22.11-installed-by-oryx" ls /opt/nodejs/ | grep 12.22.11

# Report result
reportResults