#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

echoStderr()
{
    echo "$@" 1>&2
}

checkOSPackage() {
    LABEL=$1
    PACKAGE_NAME=$2
    echo -e "\n🧪 Testing $LABEL"
    # Check if the package exists and retrieve its exact version
    if [ "$(dpkg-query -W -f='${Status}' "$PACKAGE_NAME" 2>/dev/null | grep -c "ok installed")" -eq 1 ]; then
        echo "✅  Package '$PACKAGE_NAME' is installed."
        exit 0
    else
        echo "❌ Package '$PACKAGE_NAME' is not installed."
        exit 1
    fi
}

check "desktop-init-exists" bash -c "ls /usr/local/share/desktop-init.sh"
check "log-exists" bash -c "ls /tmp/container-init.log"

. /etc/os-release
if [ "${ID}" = "ubuntu" ]; then
    if [ "${VERSION_CODENAME}" = "noble" ]; then
        checkOSPackage "if libasound2-dev exists !" "libasound2-dev"
    else 
        checkOSPackage "if libasound2 exists !" "libasound2"
    fi
else 
    checkOSPackage "if libasound2 exists !" "libasound2"
fi

# Report result
reportResults