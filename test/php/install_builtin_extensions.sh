#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "php-version-8-is-installed" bash -c "php --version | grep '8.'"
check "php-intl-extension-installed" bash -c "php -m | grep 'intl'"
check "php-zip-extension-installed" bash -c "php -m | grep 'zip'"
check "php-pgsql-extension-installed" bash -c "php -m | grep 'pdo_pgsql'"
check "php-ldap-extension-installed" bash -c "php -m | grep 'ldap'"

# Report result
reportResults
