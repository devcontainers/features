#!/bin/bash

set -e

source dev-container-features-test-lib

pushd example_project
check "dotnet restore" dotnet restore
check "dotnet build" dotnet build
