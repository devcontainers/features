#!/bin/bash

# Optional: Import test library
source dev-container-features-test-lib

check "installs compose-switch as docker-compose" bash -c "[[ -f /usr/local/bin/docker-compose ]]"

# Fetch host/container arch.
architecture="$(dpkg --print-architecture)"

repo_url="https://api.github.com/repos/docker/compose-switch/releases"

# Function to fetch the previous version of the plugin
get_previous_version() {
    sudo curl -s "$repo_url" | jq -r 'del(.[].assets) | .[0].tag_name' # this would del the assets key and then get the second encountered tag_name's value from the filtered array of objects
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
    test_compose_switch_version="1.2.xyz"
    echo -e "\nTesting with $test_compose_switch_version..."
    sudo curl -fsSL "https://github.com/docker/compose-switch/releases/download/${test_compose_switch_version}/docker-compose-linux-${architecture}" -o /usr/local/bin/docker-compose || install_compose_switch_fallback
    sudo chmod +x /usr/local/bin/docker-compose
}

install_compose-switch_as_docker-compose

check "installs compose-switch as docker-compose" bash -c "[[ -f /usr/local/bin/docker-compose ]]"