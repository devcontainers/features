#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests before test for fallback
HL="\033[1;33m"
N="\033[0;37m"
echo -e "\n👉${HL} docker/buildx version as installed by docker-in-docker feature${N}"
check "docker-buildx" docker buildx version
check "docker-build" docker build ./
check "docker-buildx" bash -c "docker buildx version"
check "docker-buildx-path" bash -c "ls -la /usr/libexec/docker/cli-plugins/docker-buildx"

echo -e "\n👉${HL} Creating a scenario for fallback${N}\n"
# Code to test the made up scenario when latest version of docker/buildx fails on wget command for fetching the artifacts
repo_url="https://api.github.com/repos/docker/buildx/releases" # GitHub repository URL
architecture="$(dpkg --print-architecture)"

# Function to fetch the latest version of the plugin
get_latest_version() {
    curl -s "$repo_url/latest" | jq -r '.tag_name'
}

# Function to fetch the previous version of the plugin
get_previous_version() {
    # this would del the assets key and then get the first encountered tag_name's value from the filtered array of objects
    curl -s "$repo_url" | jq -r 'del(.[].assets) | .[0].tag_name'
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

change_version_to_fail() {
    latest_version=$1
    new_patch_number="xyz" # for testing a tag not found scenario for docker/buildx plugin
    latest_version=$(get_latest_version)  # can take latest_version from fn get_latest_version
    buildx_version_fallback_test=$(change_patch_number "$latest_version" "$new_patch_number") # for testing a tag not found scenario for docker/buildx plugin
    echo "${buildx_version_fallback_test}"
}

install_previous_version_artifacts() {
    wget_exit_code=$?
    if [ $wget_exit_code -ne 0 ]; then # means wget command to fetch latest version failed
        if [ $wget_exit_code -eq 8 ]; then  # failure due to 404: Not Found.
            echo -e "\n(!) Failed to fetch the latest artifacts for docker buildx ${buildx_version}..."
            previous_version=$(get_previous_version)
            echo -e "\nAttempting to install ${previous_version}"
            buildx_file_name="buildx-${previous_version}.linux-${architecture}"
            wget https://github.com/docker/buildx/releases/download/${previous_version}/${buildx_file_name}
        else
            echo "(!) Failed to download docker buildx with exit code: $wget_exit_code"
            exit 1
        fi
    fi
}

test_version=$(change_version_to_fail "$(get_latest_version)")
buildx_file_name="buildx-${test_version}.linux-${architecture}"
buildx_version=$test_version

# This wget command will fail as the wrong version won't fetch artifact
wget https://github.com/docker/buildx/releases/download/${buildx_version}/${buildx_file_name} || install_previous_version_artifacts

docker_home="/usr/libexec/docker"
cli_plugins_dir="${docker_home}/cli-plugins"

mkdir -p ${cli_plugins_dir}
mv ${buildx_file_name} ${cli_plugins_dir}/docker-buildx
chmod +x ${cli_plugins_dir}/docker-buildx

chown -R "${USERNAME}:docker" "${docker_home}"
chmod -R g+r+w "${docker_home}"
find "${docker_home}" -type d -print0 | xargs -n 1 -0 chmod g+s

# Definition specific tests after test for fallback
echo -e "\n👉${HL} docker/buildx version as installed by test for fallback${N}"
check "docker-buildx" docker buildx version
check "docker-build" docker build ./
check "docker-buildx" bash -c "docker buildx version"
check "docker-buildx-path" bash -c "ls -la /usr/libexec/docker/cli-plugins/docker-buildx"

# Report result
reportResults
