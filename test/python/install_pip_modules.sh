#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "version" python  --version
check "pip is installed" pip --version
check "pip is installed" pip3 --version

# Check that pip modules are installed
check "click module is installed" bash -c "pip list | grep click"
check "ldap3 module is installed" bash -c "pip list | grep ldap3"


# Report result
reportResults
