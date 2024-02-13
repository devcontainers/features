#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "Oryx version" oryx --version
check "Dotnet is not removed if it is not installed by the Oryx Feature" dotnet --version

# Install platforms with oryx build tool
check "oryx-install-dotnet-2.1" oryx prep --skip-detection --platforms-and-versions dotnet=2.1.30
check "dotnet-2-installed-by-oryx" ls /opt/dotnet/ | grep 2.1

check "oryx-install-nodejs-12.22.11" oryx prep --skip-detection --platforms-and-versions nodejs=12.22.11
check "nodejs-12.22.11-installed-by-oryx" ls /opt/nodejs/ | grep 12.22.11

check "oryx-install-php-7.3.25" oryx prep --skip-detection --platforms-and-versions php=7.3.25
check "php-7.3.25-installed-by-oryx" ls /opt/php/ | grep 7.3.25

check "oryx-install-java-12.0.2" oryx prep --skip-detection --platforms-and-versions java=12.0.2
check "java-12.0.2-installed-by-oryx" ls /opt/java/ | grep 12.0.2

# Replicates Oryx's behavior for universal image
mkdir -p /opt/oryx
echo "vso-focal" >> /opt/oryx/.imagetype

mkdir -p /opt/dotnet/lts
cp -R /usr/share/dotnet/dotnet /opt/dotnet/lts
cp -R /usr/share/dotnet/LICENSE.txt /opt/dotnet/lts
cp -R /usr/share/dotnet/ThirdPartyNotices.txt /opt/dotnet/lts

# Install platforms with oryx build tool
check "oryx-install-dotnet-2.1-universal" oryx prep --skip-detection --platforms-and-versions dotnet=2.1.30
check "dotnet-2-installed-by-oryx-universal" ls /opt/dotnet/ | grep 2.1

check "oryx-install-nodejs-12.22.11-universal" oryx prep --skip-detection --platforms-and-versions nodejs=12.22.11
check "nodejs-12.22.11-installed-by-oryx-universal" ls /opt/nodejs/ | grep 12.22.11

check "oryx-install-php-7.3.25-universal" oryx prep --skip-detection --platforms-and-versions php=7.3.25
check "php-7.3.25-installed-by-oryx-universal" ls /opt/php/ | grep 7.3.25

check "oryx-install-java-12.0.2-universal" oryx prep --skip-detection --platforms-and-versions java=12.0.2
check "java-12.0.2-installed-by-oryx-universal" ls /opt/java/ | grep 12.0.2

# Report result
reportResults
