#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${script_dir}/check_asound_package.sh"

checkAsoundPackage

# Report result
reportResults
