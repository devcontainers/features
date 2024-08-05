#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "user is vscode" grep vscode <(whoami)

check "java" java --version

check "ant" ant -version
cat << EOF > /tmp/build.xml
<project><target name="init"><mkdir dir="ant-src"/></target></project>
EOF
cd /tmp && ant init
check "ant-src exists" grep "ant-src" <(ls -la /tmp)

check "gradle" gradle --version
cd /tmp && gradle init --type basic --dsl groovy --overwrite --incubating --project-name test
check "GRADLE_USER_HOME exists" grep ".gradle" <(ls -la /home/vscode)

check "maven" mvn --version
cd /tmp && mvn archetype:generate -DgroupId=com.mycompany.app -DartifactId=my-app -DarchetypeArtifactId=maven-archetype-quickstart -DarchetypeVersion=1.4 -DinteractiveMode=false
check "m2 exists" grep ".m2" <(ls -la /home/vscode)

check "groovy" groovy --version
cat << EOF > /tmp/test.groovy
println("verify")
EOF
check "groovy works" test "$(groovy /tmp/test.groovy)" = "verify"

# Report result
reportResults
