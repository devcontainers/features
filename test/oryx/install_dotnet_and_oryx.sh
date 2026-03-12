#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Runtimes are listed twice due to 'Microsoft.NETCore.App' and 'Microsoft.AspNetCore.App'
check "two versions of dotnet runtimes are present" bash -c "[ $(dotnet --list-runtimes | wc -l) -eq 4 ]"

check "Oryx version" oryx --version
check "Dotnet is not removed if it is not installed by the Oryx Feature" dotnet --version

# Install platforms with oryx build tool
check "oryx-install-dotnet-8.0" oryx prep --skip-detection --platforms-and-versions dotnet=8.0.23
check "dotnet-2-installed-by-oryx" ls /opt/dotnet/ | grep 8.0

check "oryx-install-nodejs-20.11.0" oryx prep --skip-detection --platforms-and-versions nodejs=20.11.0
check "nodejs-20.11.0-installed-by-oryx" ls /opt/nodejs/ | grep 20.11.0

check "oryx-install-php-8.1.30" oryx prep --skip-detection --platforms-and-versions php=8.1.30
check "php-8.1.30-installed-by-oryx" ls /opt/php/ | grep 8.1.30

# Replicates Oryx's behavior for universal image
mkdir -p /opt/oryx
echo "vso-focal" >> /opt/oryx/.imagetype

mkdir -p /opt/dotnet/lts
cp -R /usr/share/dotnet/dotnet /opt/dotnet/lts
cp -R /usr/share/dotnet/LICENSE.txt /opt/dotnet/lts
cp -R /usr/share/dotnet/ThirdPartyNotices.txt /opt/dotnet/lts

# Install platforms with oryx build tool
check "oryx-install-dotnet-8.0" oryx prep --skip-detection --platforms-and-versions dotnet=8.0.23
check "dotnet-2-installed-by-oryx" ls /opt/dotnet/ | grep 8.0

check "oryx-install-nodejs-20.11.0" oryx prep --skip-detection --platforms-and-versions nodejs=20.11.0
check "nodejs-20.11.0-installed-by-oryx" ls /opt/nodejs/ | grep 20.11.0

check "oryx-install-php-8.1.30" oryx prep --skip-detection --platforms-and-versions php=8.1.30
check "php-8.1.30-installed-by-oryx" ls /opt/php/ | grep 8.1.30

# Report result
reportResults
