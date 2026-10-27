#!/bin/bash

set -e

source dev-container-features-test-lib

check "aws version" aws --version
check "session-manager-plugin installed" session-manager-plugin --version

reportResults
