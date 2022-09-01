#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "Oryx version" oryx --version
check "ORYX_SDK_STORAGE_BASE_URL" echo $ORYX_SDK_STORAGE_BASE_URL
check "ENABLE_DYNAMIC_INSTALL" echo $ENABLE_DYNAMIC_INSTALL

# Install platforms with oryx build tool
check "oryx-install-dotnet-2.1" oryx prep --skip-detection --platforms-and-versions dotnet=2.1.30
check "dotnet-2-installed-by-oryx" ls /opt/dotnet/ | grep 2.1

check "oryx-install-nodejs-12.22.11" oryx prep --skip-detection --platforms-and-versions nodejs=12.22.11
check "nodejs-12.22.11-installed-by-oryx" ls /opt/nodejs/ | grep 12.22.11

check "oryx-install-php-7.3.25" oryx prep --skip-detection --platforms-and-versions php=7.3.25
check "php-7.3.25-installed-by-oryx" ls /opt/php/ | grep 7.3.25

check "oryx-install-java-12.0.2" oryx prep --skip-detection --platforms-and-versions java=12.0.2
check "java-12.0.2-installed-by-oryx" ls /opt/java/ | grep 12.0.2

# Report result
reportResults