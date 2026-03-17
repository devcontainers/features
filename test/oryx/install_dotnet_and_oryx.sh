#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Runtimes are listed twice due to 'Microsoft.NETCore.App' and 'Microsoft.AspNetCore.App'
check "two versions of dotnet runtimes are present" bash -c "[ $(dotnet --list-runtimes | wc -l) -eq 4 ]"

check "Oryx version" oryx --version
check "Dotnet is not removed if it is not installed by the Oryx Feature" dotnet --version

# Install platforms with oryx build tool
check "oryx-install-dotnet-10.0" oryx prep --skip-detection --platforms-and-versions dotnet=10.0.4
check "dotnet-10-installed-by-oryx" ls /opt/dotnet/ | grep 10.0

check "oryx-install-nodejs-24.13.0" oryx prep --skip-detection --platforms-and-versions nodejs=24.13.0
check "nodejs-24.13.0-installed-by-oryx" ls /opt/nodejs/ | grep 24.13.0

check "oryx-install-php-8.5.1" oryx prep --skip-detection --platforms-and-versions php=8.5.1
check "php-8.5.1-installed-by-oryx" ls /opt/php/ | grep 8.5.1

# Replicates Oryx's behavior for universal image
mkdir -p /opt/oryx
echo "vso-bookworm" >> /opt/oryx/.imagetype

mkdir -p /opt/dotnet/lts
cp -R /usr/share/dotnet/dotnet /opt/dotnet/lts
cp -R /usr/share/dotnet/LICENSE.txt /opt/dotnet/lts
cp -R /usr/share/dotnet/ThirdPartyNotices.txt /opt/dotnet/lts

# Install platforms with oryx build tool
check "oryx-install-dotnet-10.0" oryx prep --skip-detection --platforms-and-versions dotnet=10.0.4
check "dotnet-10-installed-by-oryx" ls /opt/dotnet/ | grep 10.0

check "oryx-install-nodejs-24.13.0" oryx prep --skip-detection --platforms-and-versions nodejs=24.13.0
check "nodejs-24.13.0-installed-by-oryx" ls /opt/nodejs/ | grep 24.13.0

check "oryx-install-php-8.5.1" oryx prep --skip-detection --platforms-and-versions php=8.5.1
check "php-8.5.1-installed-by-oryx" ls /opt/php/ | grep 8.5.1

# Report result
reportResults
