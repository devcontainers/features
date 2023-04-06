#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "version" conda --version
check "if conda-notice.txt exists" cat /usr/local/etc/vscode-dev-containers/conda-notice.txt

# Check env
check "CONDA_SCRIPT is set correctly" echo $CONDA_SCRIPT | grep "/opt/conda/etc/profile.d/conda.sh"

check-version-ge() {
    LABEL=$1
    CURRENT_VERSION=$2
    REQUIRED_VERSION=$3
    shift
    echo -e "\n🧪 Testing $LABEL: '$CURRENT_VERSION' is >= '$REQUIRED_VERSION'"
    local GREATER_VERSION=$((echo ${CURRENT_VERSION}; echo ${REQUIRED_VERSION}) | sort -V | tail -1)
    if [ "${CURRENT_VERSION}" == "${GREATER_VERSION}" ]; then
        echo "✅  Passed!"
        return 0
    else
        echoStderr "❌ $LABEL check failed."
        FAILED+=("$LABEL")
        return 1
    fi
}

certifiVersion=$(python -c "import certifi; print(certifi.__version__)")
check-version-ge "certifi" "${certifiVersion}" "2022.12.07"

cryptographyVersion=$(python -c "import cryptography; print(cryptography.__version__)")
check-version-ge "cryptography" "${cryptographyVersion}" "39.0.1"

setuptoolsVersion=$(python -c "import setuptools; print(setuptools.__version__)")
check-version-ge "setuptools" "${setuptoolsVersion}" "65.5.1"

# Report result
reportResults
