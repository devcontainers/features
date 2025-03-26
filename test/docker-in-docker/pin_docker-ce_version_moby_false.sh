#!/bin/bash

# Optional: Import test library
source dev-container-features-test-lib

check "docker-ce" bash -c "docker --version"
check "docker-ce-cli" bash -c "docker version"

#report result
reportResults