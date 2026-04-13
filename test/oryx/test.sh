#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "Oryx version" oryx --version
check "ORYX_SDK_STORAGE_BASE_URL" echo $ORYX_SDK_STORAGE_BASE_URL
check "ENABLE_DYNAMIC_INSTALL" echo $ENABLE_DYNAMIC_INSTALL

# Install platforms with oryx build tool
check "oryx-install-dotnet-8.0" oryx prep --skip-detection --platforms-and-versions dotnet=8.0.23
check "dotnet-2-installed-by-oryx" ls /opt/dotnet/ | grep 8.0

check "oryx-install-nodejs-20.11.0" oryx prep --skip-detection --platforms-and-versions nodejs=20.11.0
check "nodejs-20.11.0-installed-by-oryx" ls /opt/nodejs/ | grep 20.11.0

check "oryx-install-php-8.1.30" oryx prep --skip-detection --platforms-and-versions php=8.1.30
check "php-8.1.30-installed-by-oryx" ls /opt/php/ | grep 8.1.30

# Report result
reportResults