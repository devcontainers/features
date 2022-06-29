set -e

# Optional: Import test library
source dev-container-features-test-lib

check "version_on_path"  node -v | grep 18.4.0

check "v18_installed" ls -1 /usr/local/share/nvm/versions/node | grep 18.4.0
check "v14_installed" ls -1 /usr/local/share/nvm/versions/node | grep 14.19.3
check "v17_installed" ls -1 /usr/local/share/nvm/versions/node | grep 17.9.1


# Report result
reportResults
