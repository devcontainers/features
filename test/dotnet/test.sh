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

check "dotnet is installed in DOTNET_ROOT and execute permission is granted" \
test -x "$DOTNET_ROOT/dotnet" 

check "dotnet is symlinked correctly in /usr/bin" \
test -L /usr/bin/dotnet -a "$(readlink -f /usr/bin/dotnet)" = "$DOTNET_ROOT/dotnet"

expected=$(fetch_latest_version)

check "Latest .NET SDK version installed" \
is_dotnet_sdk_version_installed "$expected"

# Report results
# If any of the checks above exited with a non-zero exit code, the test will fail.
reportResults