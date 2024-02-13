#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "user is root" grep root <(whoami)

check "java" java --version

check "ant version" grep "Ant(TM) version 1.10.12" <(ant -version)
cat << EOF > /tmp/build.xml
<project><target name="init"><mkdir dir="ant-src"/></target></project>
EOF
cd /tmp && ant init
check "ant-src exists" grep "ant-src" <(ls -la /tmp)

check "gradle version" grep "Gradle 6.8.3" <(gradle --version)
cd /tmp && gradle init --type basic --dsl groovy --project-name test
check "GRADLE_USER_HOME exists" grep ".gradle" <(ls -la /root)

check "maven version" grep "Apache Maven 3.6.3" <(mvn --version)
cd /tmp && mvn archetype:generate -DgroupId=com.mycompany.app -DartifactId=my-app -DarchetypeArtifactId=maven-archetype-quickstart -DarchetypeVersion=1.4 -DinteractiveMode=false
check "m2 exists" grep ".m2" <(ls -la /root)

check "groovy version" grep "Groovy Version: 2.5.22" <(groovy --version)

# Report result
reportResults
