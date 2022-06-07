#!/bin/bash

# Temporary!

pushd /workspaces/features/.github/devcontainers-action

rm ./action.yml
rm -rf ./dist
rm -rf ./lib

cp /home/codespace/ci/action.yml ./action.yml
cp -r /home/codespace/ci/dist ./dist
cp -r /home/codespace/ci/lib ./lib