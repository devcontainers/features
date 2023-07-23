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

check ".NET SDK 8.0 installed" \
is_dotnet_sdk_version_installed "8.0"

check ".NET SDK 7.0 installed" \
is_dotnet_sdk_version_installed "7.0"

check ".NET SDK 6.0 installed" \
is_dotnet_sdk_version_installed "6.0"

check "Build example class library" \
dotnet build projects/multitargeting

# Report results
# If any of the checks above exited with a non-zero exit code, the test will fail.
reportResults