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

expected=$(fetch_latest_version "aspnetcore")

check "Latest ASP.NET Core Runtime version installed" \
is_aspnetcore_runtime_version_installed "$expected"

# Report results
# If any of the checks above exited with a non-zero exit code, the test will fail.
reportResults