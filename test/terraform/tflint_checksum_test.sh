#!/bin/bash

set -e

source dev-container-features-test-lib

check "tflint version" tflint --version | grep "0.60.0"

reportResults
