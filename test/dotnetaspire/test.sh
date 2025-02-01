#!/usr/bin/env bash

set -e

# Run tests with `devcontainer features test -f dotnetaspire` in the parent of the src and test folders.

# Optional: Import test library bundled with the devcontainer CLI
# See https://github.com/devcontainers/cli/blob/HEAD/docs/features/test.md#dev-container-features-test-lib
# Provides the 'check' and 'reportResults' commands.
source dev-container-features-test-lib

# Feature-specific tests
# The 'check' command comes from the dev-container-features-test-lib. Syntax is...
# check <LABEL> <cmd> [args...]
source dotnet_env.sh

check "dotnet is installed in DOTNET_ROOT and execute permission is granted" \
test -x "$DOTNET_ROOT/dotnet" 

check "dotnet 8.0 is installed" \
test "$($DOTNET_ROOT/dotnet --info | grep '8.0.')"

check "dotnet 9.0 is installed" \
test "$($DOTNET_ROOT/dotnet --info | grep '9.0.')"

check "dotnetaspire templates are installed" \
test "$DOTNET_ROOT/dotnet new aspire"

# There isn't currently a good way to check what version of the templates was installed.

# Report results
# If any of the checks above exited with a non-zero exit code, the test will fail.
reportResults