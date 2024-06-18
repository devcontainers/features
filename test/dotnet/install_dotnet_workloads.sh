#!/bin/bash

set -e

# Optional: Import test library bundled with the devcontainer CLI
# See https://github.com/devcontainers/cli/blob/HEAD/docs/features/test.md#dev-container-features-test-lib
# Provides the 'check' and 'reportResults' commands.
source dev-container-features-test-lib

# Feature-specific tests
# The 'check' command comes from the dev-container-features-test-lib. Syntax is...
# check <LABEL> <cmd> [args...]
source dotnet_env.sh
source dotnet_helpers.sh

check "Aspire is installed" \
is_dotnet_workload_installed "aspire"

check "WASM tools are installed" \
is_dotnet_workload_installed "wasm-tools"

# Report results
# If any of the checks above exited with a non-zero exit code, the test will fail.
reportResults
