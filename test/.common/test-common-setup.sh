#!/bin/bash
#-------------------------------------------------------------------------------------------------------------------------
# Tests for common-setup.sh helper functions
# These tests validate the determine_user_from_input function
#-------------------------------------------------------------------------------------------------------------------------

set -e

# Source the helper script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../src/.common/common-setup.sh"

# Test counters
PASSED=0
FAILED=0
TOTAL=0

# Helper function to run a test
run_test() {
    local test_name="$1"
    local expected="$2"
    local actual="$3"
    
    TOTAL=$((TOTAL + 1))
    
    if [ "${expected}" = "${actual}" ]; then
        echo "✓ PASS: ${test_name}"
        PASSED=$((PASSED + 1))
    else
        echo "✗ FAIL: ${test_name}"
        echo "  Expected: '${expected}'"
        echo "  Actual:   '${actual}'"
        FAILED=$((FAILED + 1))
    fi
}

# Test 1: Automatic mode finds existing user or fallback
test_automatic_no_users() {
    local result=$(determine_user_from_input "automatic")
    # Should find either a known user or fallback to root
    # On this system, there may be a UID 1000 user (like packer)
    local uid_1000_user=$(awk -v val=1000 -F ":" '$3==val{print $1}' /etc/passwd 2>/dev/null || echo '')
    local expected="${uid_1000_user:-root}"
    run_test "Automatic mode with no matching common users finds UID 1000 or root" "${expected}" "${result}"
}

# Test 2: Automatic mode with fallback user
test_automatic_with_fallback() {
    local result=$(determine_user_from_input "automatic" "vscode")
    # Should find a user or use the fallback - check if UID 1000 exists
    local uid_1000_user=$(awk -v val=1000 -F ":" '$3==val{print $1}' /etc/passwd 2>/dev/null || echo '')
    local expected="${uid_1000_user:-vscode}"
    run_test "Automatic mode with custom fallback finds UID 1000 or uses fallback" "${expected}" "${result}"
}

# Test 3: Explicit "none" should return root
test_none_returns_root() {
    local result=$(determine_user_from_input "none")
    run_test "Explicit 'none' returns root" "root" "${result}"
}

# Test 4: Explicit "none" ignores fallback
test_none_ignores_fallback() {
    local result=$(determine_user_from_input "none" "vscode")
    run_test "Explicit 'none' ignores fallback" "root" "${result}"
}

# Test 5: Existing user (root) should return root
test_existing_user_root() {
    local result=$(determine_user_from_input "root")
    run_test "Existing user 'root' returns root" "root" "${result}"
}

# Test 6: Non-existing user should return root
test_nonexisting_user() {
    local result=$(determine_user_from_input "nonexistentuser12345")
    run_test "Non-existing user returns root" "root" "${result}"
}

# Test 7: Auto mode (synonym for automatic)
test_auto_synonym() {
    local result=$(determine_user_from_input "auto" "customfallback")
    # Should behave same as automatic - find UID 1000 or use fallback
    local uid_1000_user=$(awk -v val=1000 -F ":" '$3==val{print $1}' /etc/passwd 2>/dev/null || echo '')
    local expected="${uid_1000_user:-customfallback}"
    run_test "Auto mode with fallback finds UID 1000 or uses fallback" "${expected}" "${result}"
}

# Test 8: _REMOTE_USER environment variable (when set and not root)
test_remote_user_set() {
    # Test with an existing user (root is always available)
    # We'll use a user that exists on the system
    local existing_user=$(awk -v val=1000 -F ":" '$3==val{print $1}' /etc/passwd 2>/dev/null || echo 'root')
    
    export _REMOTE_USER="${existing_user}"
    local result=$(determine_user_from_input "automatic")
    unset _REMOTE_USER
    
    run_test "_REMOTE_USER set to non-root user" "${existing_user}" "${result}"
}

# Test 9: _REMOTE_USER set to root should use fallback logic
test_remote_user_root() {
    export _REMOTE_USER="root"
    local result=$(determine_user_from_input "automatic" "mydefault")
    unset _REMOTE_USER
    
    # Should use fallback logic - find UID 1000 or use fallback
    local uid_1000_user=$(awk -v val=1000 -F ":" '$3==val{print $1}' /etc/passwd 2>/dev/null || echo '')
    local expected="${uid_1000_user:-mydefault}"
    run_test "_REMOTE_USER set to root uses fallback logic" "${expected}" "${result}"
}

# Test 10: Finding vscode user if it exists
test_find_vscode_user() {
    # Check if vscode user exists and no higher priority users exist
    if id -u vscode > /dev/null 2>&1 && \
       ! id -u devcontainer > /dev/null 2>&1; then
        # Unset _REMOTE_USER to ensure it doesn't interfere
        unset _REMOTE_USER
        local result=$(determine_user_from_input "automatic")
        # Should find vscode (it's second in priority after devcontainer)
        run_test "Finds vscode user in automatic mode" "vscode" "${result}"
    else
        # Skip this test if vscode user doesn't exist or higher priority user exists
        run_test "Finds vscode user in automatic mode (SKIPPED - conditions not met)" "SKIP" "SKIP"
    fi
}

# Test 11: Finding devcontainer user (highest priority)
test_find_devcontainer_user() {
    # Check if devcontainer user exists
    if id -u devcontainer > /dev/null 2>&1; then
        # Unset _REMOTE_USER to ensure it doesn't interfere
        unset _REMOTE_USER
        local result=$(determine_user_from_input "automatic")
        # Should find devcontainer (highest priority)
        run_test "Finds devcontainer user (highest priority)" "devcontainer" "${result}"
    else
        # Skip this test if devcontainer user doesn't exist
        run_test "Finds devcontainer user (highest priority) (SKIPPED - user doesn't exist)" "SKIP" "SKIP"
    fi
}

# Test 12: Finding user with UID 1000
test_find_uid_1000() {
    # Check if there's a user with UID 1000
    local uid_1000_user=$(awk -v val=1000 -F ":" '$3==val{print $1}' /etc/passwd 2>/dev/null || echo '')
    
    if [ -n "${uid_1000_user}" ] && \
       ! id -u devcontainer > /dev/null 2>&1 && \
       ! id -u vscode > /dev/null 2>&1 && \
       ! id -u node > /dev/null 2>&1 && \
       ! id -u codespace > /dev/null 2>&1; then
        # Only test if UID 1000 exists and no higher priority users exist
        local result=$(determine_user_from_input "automatic")
        run_test "Finds user with UID 1000" "${uid_1000_user}" "${result}"
    else
        # Skip this test if conditions aren't met
        run_test "Finds user with UID 1000 (SKIPPED - conditions not met)" "SKIP" "SKIP"
    fi
}

# Test 13: Empty input defaults to "automatic"
test_empty_input() {
    local result=$(determine_user_from_input "" "mydefault")
    # Should behave as automatic mode - find UID 1000 or use fallback
    local uid_1000_user=$(awk -v val=1000 -F ":" '$3==val{print $1}' /etc/passwd 2>/dev/null || echo '')
    local expected="${uid_1000_user:-mydefault}"
    run_test "Empty input treated as automatic and finds UID 1000 or uses fallback" "${expected}" "${result}"
}

# Test 14: _REMOTE_USER set to non-existent user should use fallback
test_remote_user_nonexistent() {
    export _REMOTE_USER="nonexistentuser99999"
    local result=$(determine_user_from_input "automatic" "mydefault")
    unset _REMOTE_USER
    
    # Should fall through to normal detection - find UID 1000 or use fallback
    local uid_1000_user=$(awk -v val=1000 -F ":" '$3==val{print $1}' /etc/passwd 2>/dev/null || echo '')
    local expected="${uid_1000_user:-mydefault}"
    run_test "_REMOTE_USER set to non-existent user falls back to detection" "${expected}" "${result}"
}

# Run all tests
echo "Running tests for common-setup.sh..."
echo "======================================"
echo ""

test_automatic_no_users
test_automatic_with_fallback
test_none_returns_root
test_none_ignores_fallback
test_existing_user_root
test_nonexisting_user
test_auto_synonym
test_remote_user_set
test_remote_user_root
test_find_vscode_user
test_find_devcontainer_user
test_find_uid_1000
test_empty_input
test_remote_user_nonexistent

# Print summary
echo ""
echo "======================================"
echo "Test Summary:"
echo "  Total:  ${TOTAL}"
echo "  Passed: ${PASSED}"
echo "  Failed: ${FAILED}"
echo "======================================"

# Exit with appropriate code
if [ ${FAILED} -eq 0 ]; then
    echo "All tests passed! ✓"
    exit 0
else
    echo "Some tests failed! ✗"
    exit 1
fi
