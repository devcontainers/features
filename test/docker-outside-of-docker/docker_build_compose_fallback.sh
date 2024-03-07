#!/bin/bash

# Optional: Import test library
source dev-container-features-test-lib

check "installs compose-switch as docker-compose" bash -c "[[ -f /usr/local/bin/docker-compose ]]"

# Fetch host/container arch.
architecture="$(dpkg --print-architecture)"

repo_url="https://api.github.com/repos/docker/compose-switch/releases"

# Function to fetch the latest version of the plugin
get_latest_version() {
    sudo curl -s "$repo_url/latest" | jq -r '.tag_name'
}

# Function to fetch the previous version of the plugin
get_previous_version() {
    sudo curl -s "$repo_url" | jq -r 'del(.[].assets) | .[1].tag_name' # this would del the assets key and then get the second encountered tag_name's value from the filtered array of objects
}

desired_version=$(get_latest_version)
desired_version=${desired_version#v}

check_docker_compose_version() {
    
    # Check if docker-compose-switch is installed and get its version
    docker_compose_version=$(docker-compose version --short 2>/dev/null)

    if [ -n "$docker_compose_version" ]; then
        # Docker Compose is installed
        echo -e "\nInstalled docker-compose version: $docker_compose_version"
        
        # Check if installed version matches the desired version
        if [ "$docker_compose_version" = "$desired_version" ]; then
            echo -e "\ndocker-compose version $desired_version is installed."
        else
            echo -e "\ndocker-compose version $desired_version is not installed."
        fi
    else
        # Docker Compose is not installed
        echo -e "\ndocker-compose is not installed."
    fi
}

check_docker_compose_version

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
    new_patch_number="xyz" # for testing a tag not found scenario for docker/buildx plugin
    latest_version=$(get_latest_version)  # can take latest_version from fn get_latest_version
    compose_version_fallback_test=$(change_patch_number "$latest_version" "$new_patch_number") # for testing a tag not found scenario for docker/buildx plugin
    echo "${compose_version_fallback_test}"
}

install_compose_switch_fallback() {
    echo -e "\n(!) Failed to fetch the latest artifacts for compose-switch ${test_compose_switch_version}..."
    previous_version=$(get_previous_version)
    echo -e "\nAttempting to install ${previous_version}"
    compose_switch_version=${previous_version}
    sudo curl -fsSL "https://github.com/docker/compose-switch/releases/download/${compose_switch_version}/docker-compose-linux-${architecture}" -o /usr/local/bin/docker-compose
}

install_compose-switch_as_docker-compose() {
    echo "(*) Installing compose-switch as docker-compose..."
    test_compose_switch_version=$(change_version_to_fail)
    echo -e "\nTesting with $test_compose_switch_version..."
    sudo curl -fsSL "https://github.com/docker/compose-switch/releases/download/${test_compose_switch_version}/docker-compose-linux-${architecture}" -o /usr/local/bin/docker-compose || install_compose_switch_fallback
    sudo chmod +x /usr/local/bin/docker-compose
}

install_compose-switch_as_docker-compose

desired_version=$(get_previous_version)
desired_version=${desired_version#v}

check_docker_compose_version

check "installs compose-switch as docker-compose" bash -c "[[ -f /usr/local/bin/docker-compose ]]"