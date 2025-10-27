#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Check what verification method was used
grep -E "(COSIGN|GPG).*VERIFICATION.*PATH" /var/log/* 2>/dev/null || echo "No verification logs found"

# Check if cosign was installed
ls -la /usr/bin/cosign 2>/dev/null || echo "Cosign binary not found"

# Check Python version that was installed
python3 --version

# Check if any cosign-related files exist
find /tmp /var/tmp -name "*cosign*" 2>/dev/null || echo "No cosign files found"

# Check build output for verification messages
docker build --progress=plain . 2>&1 | grep -E "(COSIGN|GPG).*VERIFICATION"  || echo "No verification messages found in build output"