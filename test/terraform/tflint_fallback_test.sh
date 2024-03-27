#!/bin/bash

set -e

# Import test library for `check` command
source dev-container-features-test-lib

# Check to make sure the user is vscode
check "user is vscode" whoami | grep vscode

set_error_handler() {
    echo "Error occurred on line: $LINENO"
}

# Register the error handler function to be triggered on ERR signal
trap 'set_error_handler' ERR

TFLINT_SHA256="automatic"

GPG_KEY_SERVERS="keyserver hkps://keyserver.ubuntu.com
keyserver hkps://keys.openpgp.org
keyserver hkps://keyserver.pgp.com"

check "tflint version as installed by feature" tflint --version
check "cosign version as installed by feature" cosign version

architecture="$(uname -m)"
case ${architecture} in
    x86_64) architecture="amd64";;
    aarch64 | armv8*) architecture="arm64";;
    aarch32 | armv7* | armvhf*) architecture="arm";;
    i?86) architecture="386";;
    *) echo "(!) Architecture ${architecture} unsupported"; exit 1 ;;
esac

# Figure out correct version of a three part version number is not passed
find_version_from_git_tags() {
    local variable_name=$1
    local requested_version=${!variable_name}
    if [ "${requested_version}" = "none" ]; then return; fi
    local repository=$2
    local prefix=${3:-"tags/v"}
    local separator=${4:-"."}
    local last_part_optional=${5:-"false"}    
    if [ "$(echo "${requested_version}" | grep -o "." | wc -l)" != "2" ]; then
        local escaped_separator=${separator//./\\.}
        local last_part
        if [ "${last_part_optional}" = "true" ]; then
            last_part="(${escaped_separator}[0-9]+)?"
        else
            last_part="${escaped_separator}[0-9]+"
        fi
        local regex="${prefix}\\K[0-9]+${escaped_separator}[0-9]+${last_part}$"
        local version_list="$(git ls-remote --tags ${repository} | grep -oP "${regex}" | tr -d ' ' | tr "${separator}" "." | sort -rV)"
        if [ "${requested_version}" = "latest" ] || [ "${requested_version}" = "current" ] || [ "${requested_version}" = "lts" ]; then
            declare -g ${variable_name}="$(echo "${version_list}" | head -n 1)"
        else
            set +e
            declare -g ${variable_name}="$(echo "${version_list}" | grep -E -m 1 "^${requested_version//./\\.}([\\.\\s]|$)")"
            set -e
        fi
    fi
    if [ -z "${!variable_name}" ] || ! echo "${version_list}" | grep "^${!variable_name//./\\.}$" > /dev/null 2>&1; then
        echo -e "Invalid ${variable_name} value: ${requested_version}\nValid values:\n${version_list}" >&2
        exit 1
    fi
    echo "${variable_name}=${!variable_name}"
}

# Use semver logic to decrement a version number then look for the closest match
find_prev_version_from_git_tags() {
    local variable_name=$1
    local current_version=${!variable_name}
    local repository=$2
    # Normally a "v" is used before the version number, but support alternate cases
    local prefix=${3:-"tags/v"}
    # Some repositories use "_" instead of "." for version number part separation, support that
    local separator=${4:-"."}
    # Some tools release versions that omit the last digit (e.g. go)
    local last_part_optional=${5:-"false"}
    # Some repositories may have tags that include a suffix (e.g. actions/node-versions)
    local version_suffix_regex=$6
    # Try one break fix version number less if we get a failure. Use "set +e" since "set -e" can cause failures in valid scenarios.
    set +e
        major="$(echo "${current_version}" | grep -oE '^[0-9]+' || echo '')"
        minor="$(echo "${current_version}" | grep -oP '^[0-9]+\.\K[0-9]+' || echo '')"
        breakfix="$(echo "${current_version}" | grep -oP '^[0-9]+\.[0-9]+\.\K[0-9]+' 2>/dev/null || echo '')"

        if [ "${minor}" = "0" ] && [ "${breakfix}" = "0" ]; then
            ((major=major-1))
            declare -g ${variable_name}="${major}"
            # Look for latest version from previous major release
            find_version_from_git_tags "${variable_name}" "${repository}" "${prefix}" "${separator}" "${last_part_optional}"
        # Handle situations like Go's odd version pattern where "0" releases omit the last part
        elif [ "${breakfix}" = "" ] || [ "${breakfix}" = "0" ]; then
            ((minor=minor-1))
            declare -g ${variable_name}="${major}.${minor}"
            # Look for latest version from previous minor release
            find_version_from_git_tags "${variable_name}" "${repository}" "${prefix}" "${separator}" "${last_part_optional}"
        else
            ((breakfix=breakfix-1))
            if [ "${breakfix}" = "0" ] && [ "${last_part_optional}" = "true" ]; then
                declare -g ${variable_name}="${major}.${minor}"
            else 
                declare -g ${variable_name}="${major}.${minor}.${breakfix}"
            fi
        fi
    set -e
}

# Function to fetch the version released prior to the latest version
get_previous_version() {
    local url=$1
    local repo_url=$2
    local variable_name=$3
    local mode=$4
    prev_version=${!variable_name}
    
    output=$(curl -s "$repo_url");
    # checking if jq package exists
    if ! command -v jq &> /dev/null
    then
        echo "jq could not be found, attempting to install..."
        apt-get update && apt-get install -y jq
    fi
    message=$(echo "$output" | jq -r '.message')
    if [[ "$mode" == "mode1" ]]; then
        message="API rate limit exceeded";
    elif [[ "$mode" == "mode2" ]]; then
        message=""
    fi 
    if [[ $message == "API rate limit exceeded"* ]]; then
        echo -e "\nAn attempt to find latest version using GitHub Api Failed... \nReason: ${message}"
        echo -e "\nAttempting to find latest version using GitHub tags."
        find_prev_version_from_git_tags prev_version "$url" "tags/v"
        declare -g ${variable_name}="${prev_version}"
    else
        echo -e "\nAttempting to find latest version using GitHub Api."
        version=$(echo "$output" | jq -r '.tag_name')
        declare -g ${variable_name}="${version#v}"
    fi  
    echo "${variable_name}=${!variable_name}"
}

get_github_api_repo_url() {
    local url=$1
    echo "${url/https:\/\/github.com/https:\/\/api.github.com\/repos}/releases/latest"
}

get_pkg_name() {
    local input_string="$1"
    local lowercase_input="${input_string,,}"  # Convert to lowercase
    local suffix="_version"
    local substring="${lowercase_input%$suffix*}"  # Remove suffix and everything after it
    echo "$substring"
}

install_previous_version() {
    given_version=$1
    requested_version=${!given_version}
    local URL=$2
    local mode=$3
    local REPO_URL=$(get_github_api_repo_url "$URL")
    local PKG_NAME=$(get_pkg_name "${given_version}")
    echo -e "\n(!) Failed to fetch the latest artifacts for ${PKG_NAME} v${requested_version}..."
    get_previous_version "$URL" "$REPO_URL" requested_version $mode
    echo -e "\nAttempting to install ${requested_version}"
    declare -g ${given_version}="${requested_version#v}"
    INSTALLER_FN="install_${PKG_NAME}"
    $INSTALLER_FN "${!given_version}"
    echo "${given_version}=${!given_version}"
}

# Function to check if URL returns 404
check_failure() {
    local url="$1"
    local resp_code=$2
    local response_code=$(curl -o /dev/null -s -w "%{http_code}\n" "$url")
    declare -g ${resp_code}="$response_code"
}

install_cosign() {
    COSIGN_VERSION=$1
    local URL=$2
    local mode=$3
    cosign_filename="/tmp/cosign_${COSIGN_VERSION}_${architecture}.deb"
    cosign_url="https://github.com/sigstore/cosign/releases/latest/download/cosign_${COSIGN_VERSION}_${architecture}.deb"
    resp_code=200
    check_failure "$cosign_url" resp_code
    if [ "$resp_code" -eq 404 ] || [ "$resp_code" -eq 302 ]; then
        echo -e "\n(!) Failed to fetch the latest artifacts for cosign v${COSIGN_VERSION}..."
        REPO_URL=$(get_github_api_repo_url "$URL")
        get_previous_version "$URL" "$REPO_URL" COSIGN_VERSION $mode
        echo -e "\nAttempting to install ${COSIGN_VERSION}"
        cosign_filename="/tmp/cosign_${COSIGN_VERSION}_${architecture}.deb"
        cosign_url="https://github.com/sigstore/cosign/releases/latest/download/cosign_${COSIGN_VERSION}_${architecture}.deb"
        curl -L "${cosign_url}" -o $cosign_filename
    else 
        curl -L "${cosign_url}" -o $cosign_filename
    fi
    dpkg -i $cosign_filename
    rm $cosign_filename
    echo "Installation of cosign succeeded with ${COSIGN_VERSION}."
}

# Install 'cosign' for validating signatures
# https://docs.sigstore.dev/cosign/overview/
ensure_cosign() {
    mode=$1
    if ! type cosign > /dev/null 2>&1; then
        echo -e "\nAttempting to install dummy cosign version..."
        COSIGN_VERSION="2.2.xyz"
        echo "Installing cosign... v${COSIGN_VERSION}"
        cosign_url='https://github.com/sigstore/cosign'
        install_cosign "${COSIGN_VERSION}" "${cosign_url}" $mode
    fi
    if ! type cosign > /dev/null 2>&1; then
        echo "(!) Failed to install cosign."
        exit 1
    fi
    cosign version
}

install_tflint() {
    TFLINT_VERSION=$1
    curl -sSL -o /tmp/tf-downloads/${TFLINT_FILENAME} https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VERSION}/${TFLINT_FILENAME}
}


try_install_dummy_tflint_cosign_version() {
    mode=$1
    tflint_url='https://github.com/terraform-linters/tflint'
    mkdir -p /tmp/tf-downloads
    cd /tmp/tf-downloads
    echo -e "\nTrying to install dummy tflint version..."
    TFLINT_VERSION="0.50.XYZ"
    echo "Downloading tflint...v${TFLINT_VERSION}"
    TFLINT_FILENAME="tflint_linux_${architecture}.zip"
    install_tflint "$TFLINT_VERSION"
    if grep -q "Not Found" "/tmp/tf-downloads/${TFLINT_FILENAME}"; then 
        install_previous_version TFLINT_VERSION "$tflint_url" $mode
    fi
    if [ "${TFLINT_SHA256}" != "dev-mode" ]; then

        if [ "${TFLINT_SHA256}" != "automatic" ]; then
            echo "${TFLINT_SHA256} *${TFLINT_FILENAME}" > tflint_checksums.txt
            sha256sum --ignore-missing -c tflint_checksums.txt
        else
            curl -sSL -o tflint_checksums.txt https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VERSION}/checksums.txt

            set +e
            curl -sSL -o checksums.txt.keyless.sig https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VERSION}/checksums.txt.keyless.sig
            set -e
            
            # Check that checksums.txt.keyless.sig exists and is not empty
            if [ -s checksums.txt.keyless.sig ]; then
                # Validate checksums with cosign
                curl -sSL -o checksums.txt.pem https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VERSION}/checksums.txt.pem
                ensure_cosign $mode
                cosign verify-blob \
                    --certificate=/tmp/tf-downloads/checksums.txt.pem \
                    --signature=/tmp/tf-downloads/checksums.txt.keyless.sig \
                    --certificate-identity-regexp="^https://github.com/terraform-linters/tflint"  \
                    --certificate-oidc-issuer=https://token.actions.githubusercontent.com \
                    /tmp/tf-downloads/tflint_checksums.txt
                # Ensure that checksums.txt has $TFLINT_FILENAME
                grep ${TFLINT_FILENAME} /tmp/tf-downloads/tflint_checksums.txt
                # Validate downloaded file
                sha256sum --ignore-missing -c tflint_checksums.txt
            else
                # Fallback to older, GPG-based verification (pre-0.47.0 of tflint)
                curl -sSL -o tflint_checksums.txt.sig https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VERSION}/checksums.txt.sig
                curl -sSL -o tflint_key "${TFLINT_GPG_KEY_URI}"
                gpg -q --import tflint_key
                gpg --verify tflint_checksums.txt.sig tflint_checksums.txt
            fi
        fi
    fi

    unzip /tmp/tf-downloads/${TFLINT_FILENAME}
    sudo mv -f tflint /usr/local/bin/
}

try_install_dummy_tflint_cosign_version "mode1"

check "tflint version as installed when mode=1" tflint --version
check "cosign version as installed when mode=1" cosign version

try_install_dummy_tflint_cosign_version "mode2"

check "tflint version as installed when mode=2" tflint --version
check "cosign version as installed when mode=2" cosign version