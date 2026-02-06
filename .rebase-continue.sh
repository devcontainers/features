#!/bin/bash
set -e
cd /workspaces/features
git add -A
GIT_EDITOR=true git rebase --continue 2>&1 || true
# Loop to handle remaining conflicts automatically
while [ -d .git/rebase-merge ]; do
    echo "=== Checking for conflicts ==="
    if grep -rl '<<<<<<< HEAD' src/ test/ scripts/ .gitignore SHARED_CODE.md 2>/dev/null; then
        echo "=== Conflicts found, resolving by keeping HEAD ==="
        # For each conflicted file, take HEAD version
        for f in $(grep -rl '<<<<<<< HEAD' src/ test/ scripts/ .gitignore SHARED_CODE.md 2>/dev/null); do
            # Use git checkout --theirs/--ours won't work mid-rebase the way we need
            # Instead, strip conflict markers keeping HEAD (ours in rebase = main)
            python3 -c "
import re, sys
with open('$f', 'r') as fh:
    content = fh.read()
# In rebase, HEAD = the branch being rebased onto (main)
# Remove conflict blocks, keeping HEAD content
pattern = r'<<<<<<<[^\n]*\n(.*?)=======\n.*?>>>>>>>[^\n]*\n'
resolved = re.sub(pattern, r'\1', content, flags=re.DOTALL)
with open('$f', 'w') as fh:
    fh.write(resolved)
" 2>/dev/null || echo "Failed to resolve $f"
        done
    fi
    git add -A
    GIT_EDITOR=true git rebase --continue 2>&1 || true
done
echo "=== Rebase complete ==="
git log --oneline -5
# Cleanup
rm -f /workspaces/features/.rebase-continue.sh
