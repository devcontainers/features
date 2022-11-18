#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "ensure i am user codespace"  bash -c "whoami | grep 'codespace'"

echo "Echoing contents of '/home/codespace/' ...."
ls -la /home/codespace/

echo "Echoing contents of '/home/codespace/.dotnet' ...."
ls -la /home/codespace/.dotnet/

check  "symlinked '/home/codespace/.dotnet' folder has the correct permissions"  bash -c "ls -la /home/codespace | grep -E 'lrwxrwxrwx 1 codespace codespace  (.*) .dotnet -> /usr/local/dotnet/current'"



check "A file following the symlink has the correct permissions" bash -c ""

./install_dotnet_7_jammy.sh

# Report result
reportResults
