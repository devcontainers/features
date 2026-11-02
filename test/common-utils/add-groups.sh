#!/bin/bash

set -e

source dev-container-features-test-lib

check "non-root user" id alternate
check "dialout group exists" getent group dialout
check "plugdev group exists" getent group plugdev
check "alternate in dialout" bash -lc "id -nG alternate | tr ' ' '\n' | grep -Fx dialout"
check "alternate in plugdev" bash -lc "id -nG alternate | tr ' ' '\n' | grep -Fx plugdev"

reportResults