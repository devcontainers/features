#!/bin/bash

set -e

export DOTNET_NOLOGO=true
export DOTNET_SKIP_FIRST_TIME_EXPERIENCE=true
export DOTNET_GENERATE_ASPNET_CERTIFICATE=false

# Optional: Import test library bundled with the devcontainer CLI
# See https://github.com/devcontainers/cli/blob/HEAD/docs/features/test.md#dev-container-features-test-lib
# Provides the 'check' and 'reportResults' commands.
source dev-container-features-test-lib

# Feature-specific tests
# The 'check' command comes from the dev-container-features-test-lib. Syntax is...
# check <LABEL> <cmd> [args...]

is_installed_dotnet_sdk_version() {
    dotnet --list-sdks | grep -q $1
    return $?
}

# The version will have to be updated as time moves on, sorry
check ".NET SDK 7.0 installed" is_installed_dotnet_sdk_version "7.0"
check "Example project" dotnet run --project projects/net7.0 

# Report results
# If any of the checks above exited with a non-zero exit code, the test will fail.
reportResults