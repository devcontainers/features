#!/bin/bash

set -e

# Import test library for `check` command
source dev-container-features-test-lib

check "less is installed, pagination works !" less --version
check "less binary installation path" which less
check "Testing paginated output with less" ls -R / | less

# Report result
reportResults