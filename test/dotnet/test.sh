#!/bin/bash

set -e

# Import test library
source featuresTest.library.sh root

# Definition specific tests
check "dotnet" dotnet --info
check "sdks" dotnet --list-sdks

# Report result
reportResults