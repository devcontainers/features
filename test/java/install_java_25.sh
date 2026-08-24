#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

echo 'public class HelloWorld { public static void main(String[] args) { System.out.println("Hello, World!"); } }' > HelloWorld.java
javac HelloWorld.java

check "hello world with Java 25" /bin/bash -c 'java HelloWorld | grep "Hello, World!"'
check "Java 25 installed as default" grep 'openjdk 25\.' <(java --version)
check "Java 25 Microsoft candidate with build metadata installed" grep -E '^25\.[0-9.]+\+[0-9]+-ms$' <(ls /usr/local/sdkman/candidates/java)

# Report result
reportResults