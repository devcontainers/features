#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Tests the tag-resolution pipeline used by src/copilot-cli/install.sh for the
# "prerelease" channel. The `git ls-remote` part is intentionally not exercised;
# fixtures are piped directly into the same awk|sed|grep|sort|tail pipeline.

# Regression: alphabetic sort would pick v1.0.9; version sort must pick v1.0.45 (issue #1646).
basic=$'abc1234\trefs/tags/v1.0.1\ndef5678\trefs/tags/v1.0.9\nghi9012\trefs/tags/v1.0.10\njkl3456\trefs/tags/v1.0.45\nmno7890\trefs/tags/v1.0.2'
check "picks highest semver (v1.0.45, not v1.0.9)" bash -c "
    result=\$(printf '%s\n' \"$basic\" \
        | awk '{print \$2}' | sed 's|refs/tags/||' \
        | grep -E '^v[0-9]+\\.[0-9]+\\.[0-9]+(-[0-9]+)?\$' \
        | sort -V | tail -n1)
    [ \"\$result\" = 'v1.0.45' ]
"

# Numeric prerelease suffixes: -10 > -2 (not alphabetic).
prerelease=$'abc1234\trefs/tags/v1.0.44\ndef5678\trefs/tags/v1.0.45-1\nghi9012\trefs/tags/v1.0.45-10\njkl3456\trefs/tags/v1.0.45-2\nmno7890\trefs/tags/v1.0.45'
check "picks highest prerelease suffix (v1.0.45-10)" bash -c "
    result=\$(printf '%s\n' \"$prerelease\" \
        | awk '{print \$2}' | sed 's|refs/tags/||' \
        | grep -E '^v[0-9]+\\.[0-9]+\\.[0-9]+(-[0-9]+)?\$' \
        | sort -V | tail -n1)
    [ \"\$result\" = 'v1.0.45-10' ]
"

# Stray refs (latest, nightly, etc.) must be filtered out.
stray=$'abc1234\trefs/tags/latest\ndef5678\trefs/tags/v1.0.3\nghi9012\trefs/tags/nightly\njkl3456\trefs/tags/v1.0.20'
check "ignores non-version tags" bash -c "
    result=\$(printf '%s\n' \"$stray\" \
        | awk '{print \$2}' | sed 's|refs/tags/||' \
        | grep -E '^v[0-9]+\\.[0-9]+\\.[0-9]+(-[0-9]+)?\$' \
        | sort -V | tail -n1)
    [ \"\$result\" = 'v1.0.20' ]
"

# Anchored regex must reject tags with trailing junk (e.g. v1.0.5-rc1, v1.0.6foo).
anchored=$'a\trefs/tags/v1.0.5\nb\trefs/tags/v1.0.5-rc1\nc\trefs/tags/v1.0.6foo'
check "anchored regex rejects v1.0.5-rc1 and v1.0.6foo" bash -c "
    result=\$(printf '%s\n' \"$anchored\" \
        | awk '{print \$2}' | sed 's|refs/tags/||' \
        | grep -E '^v[0-9]+\\.[0-9]+\\.[0-9]+(-[0-9]+)?\$' \
        | sort -V | tail -n1)
    [ \"\$result\" = 'v1.0.5' ]
"

# Empty input must produce empty output (no crash, no garbage).
check "empty input -> empty output" bash -c "
    result=\$(printf '' \
        | awk '{print \$2}' | sed 's|refs/tags/||' \
        | grep -E '^v[0-9]+\\.[0-9]+\\.[0-9]+(-[0-9]+)?\$' \
        | sort -V | tail -n1)
    [ -z \"\$result\" ]
"

# No matching tags -> empty output.
nomatch=$'a\trefs/tags/main\nb\trefs/tags/HEAD'
check "no version tags -> empty output" bash -c "
    result=\$(printf '%s\n' \"$nomatch\" \
        | awk '{print \$2}' | sed 's|refs/tags/||' \
        | grep -E '^v[0-9]+\\.[0-9]+\\.[0-9]+(-[0-9]+)?\$' \
        | sort -V | tail -n1)
    [ -z \"\$result\" ]
"

# Report result
reportResults
