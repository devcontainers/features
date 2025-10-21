#!/bin/bash

set -e
source dev-container-features-test-lib

echo "=== Python Signature Verification Check ==="

# Find all Python versions
PRIMARY_VERSION=$(python3 --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
echo "Primary: $PRIMARY_VERSION"

declare -A VERSIONS
VERSIONS["$PRIMARY_VERSION"]="python3"

for py in /usr/local/python/*/bin/python3; do
    if [ -x "$py" ] && [[ "$py" != *"/current/"* ]]; then
        ver=$($py --version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
        if [ -n "$ver" ] && [ "$ver" != "$PRIMARY_VERSION" ]; then
            VERSIONS["$ver"]="$py"
            echo "Found: $ver"
        fi
    fi
done

echo -e "\nVerification Evidence:"

# Check each version
for version in $(printf '%s\n' "${!VERSIONS[@]}" | sort -V); do
    py_cmd="${VERSIONS[$version]}"
    
    # Test functionality
    check "python $version works" $py_cmd -c "print('OK')"
    
    # Check verification evidence
    major=$(echo "$version" | cut -d. -f1)
    minor=$(echo "$version" | cut -d. -f2)
    
    if [ "$major" -eq 3 ] && [ "$minor" -ge 14 ]; then
        expected="COSIGN→GPG"
    else
        expected="GPG only"
    fi
    
    # Look for signature files
    asc_count=$(find /tmp /var/tmp -name "Python-${version}*" -name "*.asc" 2>/dev/null | wc -l)
    sig_count=$(find /tmp /var/tmp -name "Python-${version}*" -name "*.sig" 2>/dev/null | wc -l)
    
    echo "Python $version ($expected): GPG=$asc_count, COSIGN=$sig_count files"
done

# Global checks
echo -e "\nGlobal Status:"
command -v cosign >/dev/null && echo "✅ COSIGN installed" || echo "❌ COSIGN missing"
command -v gpg >/dev/null && echo "✅ GPG available" || echo "❌ GPG missing"

total_asc=$(find /tmp /var/tmp -name "*.asc" 2>/dev/null | wc -l)
total_sig=$(find /tmp /var/tmp -name "*.sig" 2>/dev/null | wc -l)
echo "Total signature files: $total_asc GPG, $total_sig COSIGN"

reportResults
