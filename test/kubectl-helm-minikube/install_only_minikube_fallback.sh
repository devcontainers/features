#!/bin/bash
set -e

# Function to handle errors
handle_error() {
    local exit_code=$?
    local line_number=$1
    local command=$2
    echo "Error occurred at line $line_number with exit code $exit_code in command $command"
    exit $exit_code
}
trap 'handle_error $LINENO ${BASH_COMMAND%% *}' ERR
echo "This is line $LINENO"

# Optional: Import test library
source dev-container-features-test-lib

HL="\033[1;33m"
N="\033[0;37m"

echo -e "\n👉${HL} minikube version as installed by kubectl-helm-minikube feature${N}:"
set +e
    check "minikube version" minikube version
set -e

## Check for fallback version installation instead of latest ( when artifact not found )

architecture="$(uname -m)"
case $architecture in
    x86_64) architecture="amd64";;
    aarch64 | armv8*) architecture="arm64";;
    aarch32 | armv7* | armvhf*) architecture="arm";;
    i?86) architecture="386";;
    *) echo "(!) Architecture $architecture unsupported"; exit 1 ;;
esac

MINIKUBE_SHA256="${MINIKUBE_SHA256:-"automatic"}"

repo_url=https://api.github.com/repos/kubernetes/minikube/releases

# Function to fetch the latest version of the plugin
get_latest_version() {
    curl -s "$repo_url/latest" | jq -r '.tag_name'
}

# Function to change the patch number in a semver version
change_patch_number() {
    local version="$1"  # Input version
    local new_patch="$2"  # New patch number
    # Extract major, minor, and current patch numbers
    local major=$(echo "$version" | cut -d. -f1)
    local minor=$(echo "$version" | cut -d. -f2)
    local current_patch=$(echo "$version" | cut -d. -f3)
    # Construct the new version with the updated patch number
    local new_version="$major.$minor.$new_patch"
    echo "$new_version"
}

# Function to fetch the previous version of the plugin
get_previous_version() {
    # this would del the assets key and then get the second encountered tag_name's value from the filtered array of objects
    curl -s "$repo_url" | jq -r 'del(.[].assets) | .[1].tag_name' 
}


latest_version=$(get_latest_version)
MINIKUBE_VERSION="$(change_patch_number ${latest_version} xyz)"
echo -e "\n👉${HL} Trying to install MINIKUBE_VERSION = ${MINIKUBE_VERSION}${N}"; 
sudo curl -sSL -o /usr/local/bin/minikube "https://storage.googleapis.com/minikube/releases/${MINIKUBE_VERSION}/minikube-linux-${architecture}"    
if [ -e "/usr/local/bin/minikube" ]; then
        if grep -q "The specified key does not exist." "/usr/local/bin/minikube"; then 
            echo -e "\n(!) Failed to fetch the latest artifacts for minikube ${MINIKUBE_VERSION}..."
            requested_version=$(get_previous_version "${repo_url}")
            echo -e "\nAttempting to install ${requested_version}"
            sudo curl -sSL -o /usr/local/bin/minikube "https://storage.googleapis.com/minikube/releases/${requested_version}/minikube-linux-${architecture}"    
            MINIKUBE_VERSION="${requested_version}"
        fi
fi
sudo chmod 0755 /usr/local/bin/minikube
if [ "$MINIKUBE_SHA256" = "automatic" ]; then
    MINIKUBE_SHA256="$(sudo curl -sSL "https://storage.googleapis.com/minikube/releases/${MINIKUBE_VERSION}/minikube-linux-${architecture}.sha256")"
fi
 ([ "${MINIKUBE_SHA256}" = "dev-mode" ] || (sudo echo "${MINIKUBE_SHA256} */usr/local/bin/minikube" | sha256sum -c -))
    if ! type minikube > /dev/null 2>&1; then
        echo '(!) minikube installation failed!'
        exit 1
    fi

echo -e "\n👉${HL} minikube version as installed by this test for fallback installation${N}:"
set +e
    check "minikube version" minikube version
set -e

# Report result
reportResults
