#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "java version openjdk 8 installed" /bin/bash -c 'java -version 2>&1 | grep "openjdk version \"1.8\."'

# Report result
reportResults