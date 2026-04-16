#!/usr/bin/env bash

set -e

rm -rf /tmp/github-cli-auth-test
mkdir -p /tmp/github-cli-auth-test/bin /tmp/github-cli-auth-test/home

cat > /tmp/github-cli-auth-test/bin/gh <<'EOF'
#!/bin/bash
set -e

LOG_FILE=/tmp/github-cli-auth-test/log
STATE_FILE=/tmp/github-cli-auth-test/state

case "$1:$2:$3" in
    auth:status:)
        [ -f "$STATE_FILE" ]
        ;;
    auth:login:--with-token)
        cat > /tmp/github-cli-auth-test/token
        echo with-token > "$LOG_FILE"
        touch "$STATE_FILE"
        ;;
    auth:login:)
        echo interactive > "$LOG_FILE"
        touch "$STATE_FILE"
        ;;
    *)
        exit 1
        ;;
esac
EOF

chmod +x /tmp/github-cli-auth-test/bin/gh

PATH="/tmp/github-cli-auth-test/bin:${PATH}" \
HOME=/tmp/github-cli-auth-test/home \
GH_TOKEN=test-token \
/usr/local/share/github-cli-auth-on-setup.sh

grep -Fxq 'with-token' /tmp/github-cli-auth-test/log
grep -Fxq 'test-token' /tmp/github-cli-auth-test/token
test -f /tmp/github-cli-auth-test/home/.config/vscode-dev-containers/github-cli-auth-already-ran
