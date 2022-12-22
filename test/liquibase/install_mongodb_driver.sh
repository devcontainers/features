#!/bin/bash

set -e

# Import test library for `check` command
source dev-container-features-test-lib

# Check to make sure the user is vscode
check "user is vscode" whoami | grep vscode

# Mongodb driver specific tests
check "liquibase mongodb driver" grep "lib/liquibase-mongodb.jar" <(liquibase --version)
check "mongodb jdbc driver" grep "lib/mongodb-jdbc.jar" <(liquibase --version)

# Report result
reportResults