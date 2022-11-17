#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "user is vscode" grep vscode <(whoami)

check "java" java --version
check "gradle" gradle --version

cd /tmp && gradle init --type basic --dsl groovy --incubating --project-name test
check "GRADLE_USER_HOME exists" grep ".gradle" <(ls -la /home/vscode)

check "maven" mvn --version
cd /tmp && mvn archetype:generate -DgroupId=com.mycompany.app -DartifactId=my-app -DarchetypeArtifactId=maven-archetype-quickstart -DarchetypeVersion=1.4 -DinteractiveMode=false
check "m2 exists" grep ".m2" <(ls -la /home/vscode)

# Report result
reportResults
