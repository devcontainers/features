#!/usr/bin/env bash
# Wrapper function that also installs JDK 11 if JDK 8 is selected since this is required for the Java extension

set -e

JAVA_VERSION="${1:-"default"}"
SDKMAN_DIR="${2:-"/usr/local/sdkman"}"
USERNAME="${USERNAME:-"${_REMOTE_USER:-"automatic"}"}"
UPDATE_RC="${4:-"true"}"
ADDITIONAL_JAVA_VERSION="11"

cd "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
chmod +x install.sh

is_jdk_8="false"
if echo "${JAVA_VERSION}" | grep -E '^8([\s\.]|$)' > /dev/null 2>&1; then
    is_jdk_8="true"
fi

# If the user selected JDK 8, install the JDK 11 as well since this is needed by the Java extension
if [ "${is_jdk_8}" = "true" ]; then
    echo "(*) Installing JDK ${ADDITIONAL_JAVA_VERSION} as Java VS Code extension requires a recent JDK..."
    ./install.sh "${ADDITIONAL_JAVA_VERSION}" "${SDKMAN_DIR}" "${USERNAME}" "${UPDATE_RC}"
    jdk_11_folder="$(ls --format=single-column ${SDKMAN_DIR}/candidates/java | grep -oE -m 1 '11\..+')"
    ln -s "${SDKMAN_DIR}/candidates/java/${jdk_11_folder}" /extension-java-home
else
    ln -s ${SDKMAN_DIR}/candidates/java/current /extension-java-home
fi

echo "(*) Installing JDK ${JAVA_VERSION}..."
./install.sh "${JAVA_VERSION}" "${SDKMAN_DIR}" "${USERNAME}" "${UPDATE_RC}"
if [ "${is_jdk_8}" = "true" ]; then
    # Set current and default version to last SDK installed
    jdk_full_version="$(ls --format=single-column "${SDKMAN_DIR}/candidates/java" | sort -rV | grep -oE -m 1 "${JAVA_VERSION}\\..+" )"
    echo "(*) Setting default JDK to ${jdk_full_version}..."
    . ${SDKMAN_DIR}/bin/sdkman-init.sh 
    sdk use java "${jdk_full_version}"
    sdk default java "${jdk_full_version}"
fi