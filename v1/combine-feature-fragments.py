#!/usr/bin/env python3

# Run from repo root.

import os

featureDirs = os.listdir('./src')

beginning = """
{
	"features": [
"""

middle = ""

end = """
	]
}
"""

count = len(featureDirs)

for fDir in featureDirs:
    count -= 1
    config = f'./src/{fDir}/feature.json'
    data = open(config, "r").read()
    middle += f'{data}'
    if count != 0:
        middle += ','
    middle += '\n'

print(f'{beginning}{middle}{end}')
