#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# go
check "version" go version

# revive
check "revive version" revive --version
check "revive is installed at correct path" bash -c "which revive | grep /go/bin/revive"

# gomodifytags
check "gomodifytags is installed at correct path" bash -c "which gomodifytags | grep /go/bin/gomodifytags"

# goplay
check "goplay is installed at correct path" bash -c "which goplay | grep /go/bin/goplay"

# gotests
check "gotests is installed at correct path" bash -c "which gotests | grep /go/bin/gotests"

# impl
check "impl is installed at correct path" bash -c "which impl | grep /go/bin/impl"

# Report result
reportResults