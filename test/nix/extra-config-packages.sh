#!/bin/bash
set -e

source dev-container-features-test-lib

check "Nix installation is not masked by a volume" bash -c "! mountpoint -q /nix"
check "Experimental features config" grep -E '^experimental-features = nix-command flakes$' /etc/nix/nix.conf
check "hello_installed" type hello
check "hello_in_default_profile" bash -lc "nix-env -p /nix/var/nix/profiles/default -q | grep -q '^hello'"

reportResults