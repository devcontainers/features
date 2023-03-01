#!/bin/bash

set -e

source dev-container-features-test-lib

check "non-root user" test "$(id -u)" -ne 0

pushd example_project
check "dotnet restore" dotnet restore
check "dotnet build" dotnet build

reportResults
