#!/bin/bash

prepare_tflint_fixtures() {
    local version
    case "$(uname -m)" in
        x86_64) architecture=amd64 ;;
        aarch64) architecture=arm64 ;;
        *) return 1 ;;
    esac
    TFLINT_FILENAME="tflint_linux_${architecture}.zip"
    mkdir -p "${test_root}/fixtures"
    for version in 0.60.0 0.59.1 0.58.1; do
        mkdir -p "${test_root}/fixtures/${version}"
        command curl -fsSL --retry 3 -o "${test_root}/fixtures/${version}/${TFLINT_FILENAME}" \
            "https://github.com/terraform-linters/tflint/releases/download/v${version}/${TFLINT_FILENAME}" || return 1
        command curl -fsSL --retry 3 -o "${test_root}/fixtures/${version}/checksums.txt" \
            "https://github.com/terraform-linters/tflint/releases/download/v${version}/checksums.txt" || return 1
        (cd "${test_root}/fixtures/${version}" && sha256sum --ignore-missing -c checksums.txt) || return 1
    done
}

run_tflint_case() {
    bash -e -c 'source "$1"; installer=$2; test_root=$3; architecture=$4; TFLINT_FILENAME=$5; execute_tflint_case "$6"' \
        bash "$(realpath "${BASH_SOURCE[0]}")" "${installer}" "${test_root}" "${architecture}" "${TFLINT_FILENAME}" "$1"
}

execute_tflint_case() (
    set -e
    local mode=$1
    local case_dir="${test_root}/${mode}"
    mkdir -p "${case_dir}/downloads" "${case_dir}/bin"
    cd "${case_dir}/downloads"
    TFLINT_VERSION=0.60.0
    TFLINT_SHA256=automatic
    tflint_url=https://github.com/terraform-linters/tflint

    curl() {
        local destination url version asset
        while [ "$#" -gt 0 ]; do
            case "$1" in
                -o) destination=$2; shift 2 ;;
                https://*) url=$1; shift ;;
                *) shift ;;
            esac
        done
        version=${url%/*}
        version=${version##*/v}
        asset=${url##*/}
        destination=${destination/\/tmp\/tf-downloads/${case_dir}/downloads}
        printf '%s/%s\n' "${version}" "${asset}" >> "${case_dir}/requests"
        if [ "${asset}" = checksums.txt ]; then
            case "${mode}:${version}" in
                missing:0.60.0|multiple:0.60.0|multiple:0.59.1|stalled:*) return 22 ;;
                empty:0.60.0) : > "${destination}"; return 0 ;;
                absent-entry:0.60.0) printf '%064d  other.zip\n' 0 > "${destination}"; return 0 ;;
            esac
        else
            case "${mode}:${version}" in
                empty-archive:0.60.0) : > "${destination}"; return 0 ;;
                missing-archive:0.60.0) printf 'Not Found' > "${destination}"; return 0 ;;
            esac
        fi
        cp "${test_root}/fixtures/${version}/${asset}" "${destination}"
        if [ "${mode}" = corrupt ] && [ "${asset}" = "${TFLINT_FILENAME}" ]; then
            printf 'corrupted' >> "${destination}"
        fi
    }

    find_prev_version_from_git_tags() {
        printf '%s\n' "${TFLINT_VERSION}" >> "${case_dir}/fallbacks"
        [ "${mode}" != stalled ] || return 0
        case "${TFLINT_VERSION}" in
            0.60.0) TFLINT_VERSION=0.59.1 ;;
            0.59.1) TFLINT_VERSION=0.58.1 ;;
        esac
    }

    install_previous_version() {
        find_prev_version_from_git_tags "$1" "$2"
        "$3" "${TFLINT_VERSION}"
    }

    verify_tflint_attestations() {
        [ -s "$1" ]
    }

    unzip() {
        command unzip "${1/\/tmp\/tf-downloads/${case_dir}/downloads}"
    }

    mv() {
        [ "$1" = -f ] && [ "$2" = tflint ] && [ "$3" = /usr/local/bin/ ]
        command mv -f "$2" "${case_dir}/bin/"
    }

    source <(sed -n '/^install_tflint() {/,/^verify_tflint_attestations() {/p' "${installer}" | \
        sed '$d;s|/tmp/tf-downloads|'"${case_dir}"'/downloads|g')
    source <(sed -n '/^if \[ "${TFLINT_VERSION}" != "none" \]; then/,/^install_terragrunt() {/p' "${installer}" | \
        sed '$d;s|/tmp/tf-downloads|'"${case_dir}"'/downloads|g')
    printf '%s\n' "${TFLINT_VERSION}" > "${case_dir}/selected-version"
)

check_tflint_installation() {
    local mode=$1 version=$2
    run_tflint_case "${mode}" || return 1
    [ "$(cat "${test_root}/${mode}/selected-version")" = "${version}" ] || return 1
    "${test_root}/${mode}/bin/tflint" --version | grep -F "TFLint version ${version}" || return 1
    cmp "${test_root}/fixtures/${version}/${TFLINT_FILENAME}" "${test_root}/${mode}/downloads/${TFLINT_FILENAME}" || return 1
    cmp "${test_root}/fixtures/${version}/checksums.txt" "${test_root}/${mode}/downloads/tflint_checksums.txt"
}

check_tflint_rejected() {
    local mode=$1
    if run_tflint_case "${mode}" > "${test_root}/${mode}.log" 2>&1; then
        return 1
    fi
    [ ! -e "${test_root}/${mode}/bin/tflint" ]
}