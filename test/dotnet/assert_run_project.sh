#!/bin/bash

set -e

source dev-container-features-test-lib

cd example_project
check "dotnet run" bash -c "dotnet run | grep 'Inception'"