#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

FAILED=()
echoStderr()
{
    echo "$@" 1>&2
}

endsWith() {
  [[ $1 = *$2 ]] && return 0 || return 1
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
    PACKAGE_LIST="libssl3t64"

    checkOSPackages "Confirm that libssl3t64 is installed" ${PACKAGE_LIST}
}

# Check that libssl3t64 is installed
checkCommon

# Definition specific tests
. /etc/os-release
check "non-root user" test "$(whoami)" = "devcontainer"
check "release" endsWith "${PRETTY_NAME}" "sid"

# Report result
reportResults