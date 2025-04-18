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

# Changing it as the dotnet SDK CDN url is not showing the right version for LTS
expected=$(resolve_version_from_aka_ms "LTS" | cut -d' ' -f3)

check "Latest LTS version installed" \
is_dotnet_sdk_version_installed "$expected"

# Report results
# If any of the checks above exited with a non-zero exit code, the test will fail.
reportResults