# Common Helper Scripts

This directory contains common helper scripts that can be shared across multiple features to avoid code duplication.

## common-setup.sh

A helper script that provides common setup functions used across multiple features.

### Functions

#### `determine_user_from_input`

Determines the appropriate non-root user based on the input username.

**Usage:**
```bash
# Source the helper script
source "${SCRIPT_DIR}/../_common/common-setup.sh"

# Determine the user
USERNAME=$(determine_user_from_input "${USERNAME}" "root")
```

**Parameters:**
- `$1` (required): Input username from feature configuration (e.g., "automatic", "auto", "none", or a specific username)
- `$2` (optional): Fallback username when no user is found in automatic mode (defaults to "root")

**Behavior:**
- **"auto" or "automatic"**: 
  - First checks if `_REMOTE_USER` environment variable is set and is not "root"
  - If `_REMOTE_USER` is root or not set, searches for an existing user from the priority list:
    1. `devcontainer`
    2. `vscode`
    3. `node`
    4. `codespace`
    5. User with UID 1000 (from `/etc/passwd`)
  - If no user is found, returns the fallback user (default: "root")
  
- **"none"**: Always returns "root"

- **Specific username**: 
  - Validates the user exists using `id -u`
  - If the user exists, returns that username
  - If the user doesn't exist, returns "root"

**Examples:**

```bash
# Basic usage with default fallback (root)
USERNAME=$(determine_user_from_input "automatic")

# With custom fallback
USERNAME=$(determine_user_from_input "automatic" "vscode")

# Explicit user
USERNAME=$(determine_user_from_input "myuser")

# None (always returns root)
USERNAME=$(determine_user_from_input "none")
```

**Return Value:**
Prints the resolved username to stdout, which can be captured using command substitution.

## Testing

Tests for the helper scripts are located in `/test/_common/`. Run the tests with:

```bash
bash test/_common/test-common-setup.sh
```

## Edge Cases

The helper handles several edge cases:

1. **Missing awk**: Some systems (like Mariner) don't have awk by default. Features should install it before sourcing the helper if needed.

2. **UID 1000 lookup**: The user with UID 1000 is included in the search as it's commonly the first non-system user created.

3. **_REMOTE_USER behavior**: When `_REMOTE_USER` is set to a non-root user, it takes priority over all other detection methods in automatic mode.

4. **Empty user list entries**: The helper safely handles empty entries in the user detection loop.

## Migration Guide

To migrate an existing feature to use the common helper:

### Before:
```bash
# Determine the appropriate non-root user
if [ "${USERNAME}" = "auto" ] || [ "${USERNAME}" = "automatic" ]; then
    USERNAME=""
    POSSIBLE_USERS=("vscode" "node" "codespace" "$(awk -v val=1000 -F ":" '$3==val{print $1}' /etc/passwd)")
    for CURRENT_USER in "${POSSIBLE_USERS[@]}"; do
        if id -u ${CURRENT_USER} > /dev/null 2>&1; then
            USERNAME=${CURRENT_USER}
            break
        fi
    done
    if [ "${USERNAME}" = "" ]; then
        USERNAME=root
    fi
elif [ "${USERNAME}" = "none" ] || ! id -u ${USERNAME} > /dev/null 2>&1; then
    USERNAME=root
fi
```

### After:
```bash
# Source common helper functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../_common/common-setup.sh"

# Determine the appropriate non-root user
USERNAME=$(determine_user_from_input "${USERNAME}" "root")
```

**Note:** For features like `common-utils` that create users and need a different fallback, use:
```bash
USERNAME=$(determine_user_from_input "${USERNAME}" "vscode")
```
