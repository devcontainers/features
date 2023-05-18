#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

cd sample-python

# Replicates Oryx's behavior for universal image
DEBIAN_FLAVOR="focal-scm"
mkdir -p /opt/oryx && echo "vso-focal" > /opt/oryx/.imagetype
echo "DEBIAN|${DEBIAN_FLAVOR}" | tr '[a-z]' '[A-Z]' > /opt/oryx/.ostype

ln -snf /usr/local/oryx/* /opt/oryx

PYTHON_PATH="/home/codespace/.python/current"
mkdir -p /home/codespace/.python
ln -snf /usr/local/python/current $PYTHON_PATH
ln -snf /usr/local/python /opt/python

export PATH="/home/codespace/.python/current/bin:${PATH}"
which python

pythonVersion=$(python -V 2>&1 | grep -Po '(?<=Python )(.+)')
pythonSite=`python -m site --user-site`
check "oryx-build-python" oryx build --property python_version="${pythonVersion}" --property packagedir="${pythonSite}" ./
check "oryx-build-python-installed" python3 -m pip list | grep mpmath
check "oryx-build-python-result" python3 ./src/solve.py

# Report result
reportResults
