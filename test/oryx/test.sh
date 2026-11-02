#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "Oryx version" oryx --version
check "ORYX_SDK_STORAGE_BASE_URL" echo $ORYX_SDK_STORAGE_BASE_URL
check "ENABLE_DYNAMIC_INSTALL" echo $ENABLE_DYNAMIC_INSTALL

check "dynamic-install-assets" bash -c '
	for asset in \
		build/__goVersions.sh \
		build/__hugoConstants.sh \
		build/__nodeVersions.sh \
		build/__pythonVersions.sh \
		build/createSymlinksForDotnet.sh \
		images/__common.sh \
		images/__sdkStorageConstants.sh \
		images/installPlatform.sh \
		images/receiveGpgKeys.sh \
		images/retry.sh \
		images/build/installHugo.sh; do
		test -x "/opt/tmp/${asset}" || exit 1
	done
	test -r /opt/tmp/images/constants.yml
'
check "source-repository-removed" test ! -e /opt/tmp/oryx-repo
check "build-tools-not-retained" test ! -e /opt/tmp/build/tools
check "image-definitions-not-retained" test ! -e /opt/tmp/images/build/Dockerfiles
check "publish-debug-artifacts-not-retained" bash -c 'test -z "$(find /usr/local/buildscriptgen -maxdepth 1 -type f \( -name "*.pdb" -o -name "Microsoft.Oryx.*.xml" -o -name "GenerateBuildScript.xml" \) -print -quit)"'

# Install platforms with oryx build tool
check "oryx-install-dotnet-8.0" oryx prep --skip-detection --platforms-and-versions dotnet=8.0.23
check "dotnet-2-installed-by-oryx" ls /opt/dotnet/ | grep 8.0

check "oryx-install-nodejs-20.11.0" oryx prep --skip-detection --platforms-and-versions nodejs=20.11.0
check "nodejs-20.11.0-installed-by-oryx" ls /opt/nodejs/ | grep 20.11.0

check "oryx-install-php-8.1.30" oryx prep --skip-detection --platforms-and-versions php=8.1.30
check "php-8.1.30-installed-by-oryx" ls /opt/php/ | grep 8.1.30

# Report result
reportResults