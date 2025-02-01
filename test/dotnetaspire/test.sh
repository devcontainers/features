#!/usr/bin/env bash

set -e

# Run tests with `devcontainer features test -f dotnetaspire` in the parent of the src and test folders.

source dev-container-features-test-lib
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

reportResults