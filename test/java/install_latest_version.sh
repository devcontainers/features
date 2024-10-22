#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

echo 'public class HelloWorld { public static void main(String[] args) { System.out.println("Hello, World!"); } }' > HelloWorld.java
javac HelloWorld.java

check "hello world" /bin/bash -c "java HelloWorld | grep "Hello, World!""
check "java version latest installed" grep "23" <(java --version)

# Report result
reportResults
