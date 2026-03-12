#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "conda" conda --version
check "python" python --version
check "pylint" pylint --version
check "flake8" flake8 --version
check "autopep8" autopep8 --version
check "yapf" yapf --version
check "pydocstyle" pydocstyle --version
check "pycodestyle" pycodestyle --version
check "if conda-notice.txt exists" cat /usr/local/etc/vscode-dev-containers/conda-notice.txt

check "certifi" pip show certifi | grep Version
check "cryptography" pip show cryptography | grep Version
check "setuptools" pip show setuptools | grep Version
check "tornado" pip show tornado | grep Version

check "conda-update-conda" bash -c "conda update -y conda"
check "conda-install-tensorflow" bash -c "conda create --name test-env -c conda-forge --yes tensorflow"
check "conda-install-pytorch" bash -c "conda create --name test-env -c conda-forge --yes pytorch"

# Report result
reportResults

