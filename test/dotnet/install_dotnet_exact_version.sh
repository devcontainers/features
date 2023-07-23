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

check ".NET SDK 8.0.100-preview.6.23330.14 installed" \
is_dotnet_sdk_version_installed "8.0.100-preview.6.23330.14"

check "Build and run example project" \
dotnet run --project projects/net8.0 

# Report results
# If any of the checks above exited with a non-zero exit code, the test will fail.
reportResults