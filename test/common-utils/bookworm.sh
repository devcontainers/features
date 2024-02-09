#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

FAILED=()
echoStderr()
{
    echo "$@" 1>&2
}

checkOSPackages() {
    LABEL=$1
    shift
    echo -e "\n🧪 Testing $LABEL"
    if dpkg-query --show -f='${Package}: ${Version}\n' "$@"; then 
        echo "✅  Passed!"
        return 0
    else
        echoStderr "❌ $LABEL check failed."
        FAILED+=("$LABEL")
        return 1
    fi
}

checkCommon()
{
    PACKAGE_LIST="manpages-posix \
        manpages-posix-dev"

    checkOSPackages "Installation of manpages-posix and manpages-posix-dev (non-free)" ${PACKAGE_LIST}
}

# Check for manpages-posix, manpages-posix-dev non-free packages
checkCommon

# Definition specific tests
. /etc/os-release
check "non-root user" test "$(whoami)" = "devcontainer"
check "distro" test "${VERSION_CODENAME}" = "bookworm"

# Report result
reportResults