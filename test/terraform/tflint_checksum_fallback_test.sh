#!/bin/bash

set -e

source dev-container-features-test-lib

TFLINT_VERSION="0.60.0"
TFLINT_FILENAME="tflint_linux_amd64.zip"
tflint_url="https://github.com/terraform-linters/tflint"
checksum_attempts=0
previous_version_requests=0
downloaded_versions=()

run_checksum_fallback() {
    while ! download_tflint_checksums; do
        current_tflint_version="${TFLINT_VERSION}"
        find_prev_version_from_git_tags TFLINT_VERSION "$tflint_url"
        if [ "${TFLINT_VERSION}" = "${current_tflint_version}" ]; then
            return 1
        fi
        install_tflint "$TFLINT_VERSION"
    done
}

download_tflint_checksums() {
    checksum_attempts=$((checksum_attempts + 1))
    [ "${checksum_attempts}" -gt 1 ]
}

find_prev_version_from_git_tags() {
    previous_version_requests=$((previous_version_requests + 1))
    TFLINT_VERSION="0.59.1"
}

install_tflint() {
    downloaded_versions+=("$1")
}

run_checksum_fallback

check "checksum download retried once" bash -c "[ \"${checksum_attempts}\" -eq 2 ]"
check "previous tflint version requested once" bash -c "[ \"${previous_version_requests}\" -eq 1 ]"
check "previous tflint archive downloaded" bash -c "[ \"${downloaded_versions[0]}\" = \"0.59.1\" ]"
check "fallback resolved to previous tflint version" bash -c "[ \"${TFLINT_VERSION}\" = \"0.59.1\" ]"

reportResults
