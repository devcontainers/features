#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

echoStderr()
{
    echo "$@" 1>&2
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${script_dir}/check_asound_package.sh"

check "desktop-init-exists" bash -c "ls /usr/local/share/desktop-init.sh"
check "log-exists" bash -c "ls /tmp/container-init.log"
check "fluxbox-exists" bash -c "ls -la ~/.fluxbox"

checkAsoundPackage

# Report result
reportResults