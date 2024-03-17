#!/bin/bash
set -e

# Optional: Import test library
source dev-container-features-test-lib
HL="\033[1;33m"
N="\033[0;37m"
echo -e "\n👉${HL} helm version as installed by kubectl-helm-minikube feature${N}:"

set +e
    check "helm version" helm version
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

## Check for fallback version installation instead of latest ( when artifact not found )
architecture="$(uname -m)"
case $architecture in
    x86_64) architecture="amd64";;
    aarch64 | armv8*) architecture="arm64";;
    aarch32 | armv7* | armvhf*) architecture="arm";;
    i?86) architecture="386";;
    *) echo "(!) Architecture $architecture unsupported"; exit 1 ;;
esac
HELM_SHA256="${HELM_SHA256:-"automatic"}"
HELM_GPG_KEYS_URI="https://raw.githubusercontent.com/helm/helm/main/KEYS"

repo_url=https://api.github.com/repos/helm/helm/releases

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
    curl -s "$repo_url" | jq -r 'del(.[].assets) | .[0].tag_name' 
}

get_helm() {
    HELM_VERSION=$1
    helm_filename="helm-${HELM_VERSION}-linux-${architecture}.tar.gz"
    tmp_helm_filename="/tmp/helm/${helm_filename}"
    sudo curl -sSL "https://get.helm.sh/${helm_filename}" -o "${tmp_helm_filename}"
    sudo curl -sSL "https://github.com/helm/helm/releases/download/${HELM_VERSION}/${helm_filename}.asc" -o "${tmp_helm_filename}.asc"
}

latest_version=$(get_latest_version)
NON_EXISTING_PATCH_VERSION="xyz"
HELM_VERSION="$(change_patch_number ${latest_version} ${NON_EXISTING_PATCH_VERSION})"
echo -e "\n👉${HL} Trying to install HELM_VERSION = ${HELM_VERSION}${N}"; 
sudo mkdir -p /tmp/helm
get_helm "${HELM_VERSION}"
if grep -q "BlobNotFound" "/tmp/helm/${helm_filename}"; then
    echo -e "\n(!) Failed to fetch the latest artifacts for helm ${HELM_VERSION}..."
    requested_version=$(get_previous_version)
    echo -e "\nAttempting to install ${requested_version}"
    HELM_VERSION=${requested_version}
    get_helm "${HELM_VERSION}"
fi
export GNUPGHOME="/tmp/helm/gnupg"
sudo mkdir -p "${GNUPGHOME}"
sudo chmod 700 ${GNUPGHOME}
sudo curl -sSL "${HELM_GPG_KEYS_URI}" -o /tmp/helm/KEYS
sudo echo -e "disable-ipv6\n${GPG_KEY_SERVERS}" | sudo tee ${GNUPGHOME}/dirmngr.conf >/dev/null
sudo gpg -q --import "/tmp/helm/KEYS"
if ! sudo gpg --verify "${tmp_helm_filename}.asc" | sudo tee ${GNUPGHOME}/verify.log 2>&1; then
    echo "Verification failed!"
    sudo cat /tmp/helm/gnupg/verify.log
    exit 1
fi

if [ "${HELM_SHA256}" = "automatic" ]; then
    sudo curl -sSL "https://get.helm.sh/${helm_filename}.sha256" -o "${tmp_helm_filename}.sha256"
    sudo curl -sSL "https://github.com/helm/helm/releases/download/${HELM_VERSION}/${helm_filename}.sha256.asc" -o "${tmp_helm_filename}.sha256.asc"
    if ! sudo gpg --verify "${tmp_helm_filename}.sha256.asc" | sudo tee /tmp/helm/gnupg/verify.log 2>&1; then
        echo "Verification failed!"
        sudo cat /tmp/helm/gnupg/verify.log
        exit 1
    fi
    HELM_SHA256="$(sudo cat "${tmp_helm_filename}.sha256")"
fi

([ "${HELM_SHA256}" = "dev-mode" ] || (sudo echo "${HELM_SHA256} *${tmp_helm_filename}" | sha256sum -c -))
sudo tar xf "${tmp_helm_filename}" -C /tmp/helm
sudo mv -f "/tmp/helm/linux-${architecture}/helm" /usr/local/bin/
sudo chmod 0755 /usr/local/bin/helm
sudo rm -rf /tmp/helm
if ! type helm > /dev/null 2>&1; then
    echo '(!) Helm installation failed!'
    exit 1
fi

echo -e "\n👉${HL} helm version as installed by test for fallback${N}:"

set +e
    check "helm version" helm version
set -e

# Report result
reportResults
