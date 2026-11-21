#!/bin/bash

set -e

# Test for git-lfs behavior with repos that have no LFS files
# This tests the fix for the issue where git lfs install was running unnecessarily

# Optional: Import test library
source dev-container-features-test-lib

# Test that git-lfs is installed
check "git-lfs version" git-lfs --version

# Test the generated script exists
check "pull script exists" test -f /usr/local/share/pull-git-lfs-artifacts.sh

# We should already be in a git repository created by initializeCommand
# Verify we're in a git repository
check "in git repository" git rev-parse --is-inside-work-tree

# Test that git lfs ls-files returns empty output
check "git lfs ls-files returns empty output" test -z "$(git lfs ls-files 2>/dev/null)"

# Verify no LFS hooks exist initially (the script should have already run during postCreateCommand)
HOOKS_COUNT=$(find .git/hooks -type f ! -name '*.sample' | wc -l)
check "no git hooks installed after postCreateCommand" test "$HOOKS_COUNT" -eq 0

# Double check: specifically look for the hooks that git lfs install would create
check "no post-merge hook" test ! -f .git/hooks/post-merge
check "no pre-push hook" test ! -f .git/hooks/pre-push
check "no post-commit hook" test ! -f .git/hooks/post-commit
check "no post-checkout hook" test ! -f .git/hooks/post-checkout

# Report results
reportResults