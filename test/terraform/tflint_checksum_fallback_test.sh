#!/bin/bash

set -e

source dev-container-features-test-lib

source "$(dirname "${BASH_SOURCE[0]}")/tflint_checksum_fallback_helper.sh"

installer="${TFLINT_TEST_INSTALLER:-/usr/local/share/terraform/install.sh}"
test_root=$(mktemp -d)
trap 'rm -rf "${test_root}"' EXIT
prepare_tflint_fixtures

check "available checksums install the requested release" check_tflint_installation success 0.60.0
check "missing checksums install the previous release" check_tflint_installation missing 0.59.1
check "empty checksums trigger fallback" check_tflint_installation empty 0.59.1
check "checksums without the archive entry trigger fallback" check_tflint_installation absent-entry 0.59.1
check "empty archive triggers fallback" check_tflint_installation empty-archive 0.59.1
check "Not Found archive triggers fallback" check_tflint_installation missing-archive 0.59.1
check "multiple unavailable releases install matching archive and checksums" check_tflint_installation multiple 0.58.1
check "each fallback downloads the replacement archive before its checksums" \
    diff -u <(printf '%s\n' \
        "0.60.0/${TFLINT_FILENAME}" 0.60.0/checksums.txt \
        "0.59.1/${TFLINT_FILENAME}" 0.59.1/checksums.txt \
        "0.58.1/${TFLINT_FILENAME}" 0.58.1/checksums.txt) "${test_root}/multiple/requests"
check "checksum mismatch prevents installation" check_tflint_rejected corrupt
check "checksum mismatch is reported" grep -F 'FAILED' "${test_root}/corrupt.log"
check "unchanged previous version fails without installing" check_tflint_rejected stalled
check "unchanged previous version stops after one attempt" \
    test "$(wc -l < "${test_root}/stalled/fallbacks")" -eq 1
check "exhausted fallback reports a useful error" \
    grep -F 'Unable to find a tflint release with downloadable checksums.' "${test_root}/stalled.log"

reportResults
