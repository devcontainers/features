#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# go
check "version" go version

# revive
check "revive version" revive --version
check "revive is installed at correct path" bash -c "type revive | grep /go/bin/revive"

# gomodifytags
check "gomodifytags is installed at correct path" bash -c "type gomodifytags | grep /go/bin/gomodifytags"

# goplay
check "goplay is installed at correct path" bash -c "type goplay | grep /go/bin/goplay"

# gotests
check "gotests is installed at correct path" bash -c "type gotests | grep /go/bin/gotests"

# impl
check "impl is installed at correct path" bash -c "type impl | grep /go/bin/impl"

# Report result
reportResults