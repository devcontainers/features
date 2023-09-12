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

# From https://learn.microsoft.com/en-us/dotnet/core/tools/global-tools
check "Install a .NET global tool" \
dotnet tool install --global dotnetsay

check "Run the tool" \
dotnetsay "$(dotnet --info)"

# Report results
# If any of the checks above exited with a non-zero exit code, the test will fail.
reportResults