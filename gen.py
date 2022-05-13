#!/usr/bin/env python3

import os

featureDirs = os.listdir('./src')


count = len(featureDirs)

for fDir in featureDirs:
    if os.path.isdir('./test/' + fDir):
        print('already exists: ', fDir)
        continue

    os.mkdir('./test/' + fDir)
    f = open(f'./test/{fDir}/test.sh', 'w')

    contents = f"""
    #!/bin/bash

    set -e

    # Optional: Import test library
    source dev-container-features-test-lib

    # Definition specific tests
    check "version" {fDir}  --version

    # Report result
    reportResults"""

    f.write(contents)
