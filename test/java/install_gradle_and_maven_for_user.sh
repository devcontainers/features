#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "java" java --version
check "gradle" gradle --version

cd /tmp && gradle init --type basic --dsl groovy --incubating --project-name test
check "GRADLE_USER_HOME exists" ls -la ~ | grep .gradle

check "maven" mvn --version
cd /tmp && mvn archetype:generate -DgroupId=com.mycompany.app -DartifactId=my-app -DarchetypeArtifactId=maven-archetype-quickstart -DarchetypeVersion=1.4 -DinteractiveMode=false
check "m2 exists" ls -la ~ | grep .m2

# Report result
reportResults
