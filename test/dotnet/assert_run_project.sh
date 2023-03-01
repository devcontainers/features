#!/bin/bash

set -e

source dev-container-features-test-lib

pushd example_project
check "dotnet run" bash -c "dotnet run | grep 'Inception'"
