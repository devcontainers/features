#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "Oryx version" oryx --version
check "Dotnet is not removed if it is not installed by the Oryx Feature" dotnet --version

# Install platforms with oryx build tool
check "oryx-install-dotnet-9.0" oryx prep --skip-detection --platforms-and-versions dotnet=9.0.1
check "dotnet-9-installed-by-oryx" ls /opt/dotnet/ | grep 9.0

check "oryx-install-nodejs-22.9.0" oryx prep --skip-detection --platforms-and-versions nodejs=22.9.0
check "nodejs-22.9.0-installed-by-oryx" ls /opt/nodejs/ | grep 22.9.0

check "oryx-install-php-8.3.20" oryx prep --skip-detection --platforms-and-versions php=8.3.20
check "php-8.3.20-installed-by-oryx" ls /opt/php/ | grep 8.3.20

# Replicates Oryx's behavior for universal image
mkdir -p /opt/oryx
echo "vso-bookworm" >> /opt/oryx/.imagetype

mkdir -p /opt/dotnet/lts
cp -R /usr/share/dotnet/dotnet /opt/dotnet/lts
cp -R /usr/share/dotnet/LICENSE.txt /opt/dotnet/lts
cp -R /usr/share/dotnet/ThirdPartyNotices.txt /opt/dotnet/lts

# Install platforms with oryx build tool
check "oryx-install-dotnet-9.0" oryx prep --skip-detection --platforms-and-versions dotnet=9.0.1
check "dotnet-9-installed-by-oryx" ls /opt/dotnet/ | grep 9.0

check "oryx-install-nodejs-22.9.0" oryx prep --skip-detection --platforms-and-versions nodejs=22.9.0
check "nodejs-22.9.0-installed-by-oryx" ls /opt/nodejs/ | grep 22.9.0

check "oryx-install-php-8.3.20" oryx prep --skip-detection --platforms-and-versions php=8.3.20
check "php-8.3.20-installed-by-oryx" ls /opt/php/ | grep 8.3.20

# Report result
reportResults
