#!/bin/bash

set -e

source dev-container-features-test-lib

check "node" node --version
check "yarn" yarn --version
check "readable Yarn keyring" test -r /etc/apt/keyrings/yarn-archive-keyring.gpg
check "Yarn repository signature" bash -o pipefail -c 'curl -fsSL https://dl.yarnpkg.com/debian/dists/stable/InRelease | gpgv --keyring /etc/apt/keyrings/yarn-archive-keyring.gpg -'
check "APT repository signatures" sudo apt-get -o APT::Update::Error-Mode=any update

reportResults