#!/bin/bash

set -e

# Import test library
source featuresTest.library.sh root

check "version" go version

# Report result
reportResults