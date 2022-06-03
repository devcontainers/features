#!/bin/bash

# Temporary!

pushd /workspaces/features/.github/devcontainers-action

rm ./action.yml
rm -rf ./dist
rm -rf ./lib

cp /home/codespace/action/action.yml ./action.yml
cp -r /home/codespace/action/dist ./dist
cp -r /home/codespace/action/lib ./lib