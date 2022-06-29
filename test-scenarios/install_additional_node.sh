set -e

# Optional: Import test library
source dev-container-features-test-lib

# 'latest' is some version of node 18 for a while.
check "version_on_path"  node -v | grep 18

check "v18_installed" ls -1 /usr/local/share/nvm/versions/node | grep 18
check "v14_installed" ls -1 /usr/local/share/nvm/versions/node | grep 14.19.3
check "v17_installed" ls -1 /usr/local/share/nvm/versions/node | grep 17.9.1


# Report result
reportResults
