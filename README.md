# Development Container Features

'Features' wrap self-contained units of installation code that applies pre-determined configuration on top of a dev container's image. A 'feature' is added to the `features` property of a [`devcontainer.json`](https://containers.dev/implementors/json_reference/#general-properties).

Development container 'features' are a [proposed](https://github.com/devcontainers/spec/blob/main/proposals/devcontainer-features.md) addition to the [development container specification](https://github.com/devcontainers/spec/blob/main/proposals/devcontainer-features.md). **Please note that 'features' are in preview and subject to breaking changes**.

## Repo Structure

```
.
├── lib
│   └── utils.sh
├── README.md
├── settings.env
├── src
│   ├── dotnet
│   │   ├── feature.json
│   │   └── install.sh
│   ├── go
│   │   ├── feature.json
│   │   └── install.sh
|   ├── ...
│   │   ├── feature.json
│   │   └── install.sh
├── test
│   ├── dotnet
│   │   └── test.sh
│   └── go
│   |   └── test.sh
|   ├── ...
│   │   ├── feature.json
│   │   └── install.sh
├── test-scenarios
│   ├── install_jupyterlab.sh
│   ├── install_python_twice.sh
|   ├── ...
│   └── scenarios.json
```

- [`lib`](lib) - A general collection of useful 'features' tools and scripts (see [./lib/utils.sh](./lib/utils.sh)). _Currently, just a mirror of functions copy/pasted into scripts_.
- [settings.env] - Override settings that features in this repo are programmed to reach out to. _Currently, scripts still point to the [vscode-dev-containers](https://github.com/microsoft/vscode-dev-containers/blob/main/script-library/shared/settings.env) copy._
- [`src`](src) - A folder-per-feature, with at least a `feature.json` and the appropriately declared install script.
- [`test`](test) - Mirroring `src`, a folder-per-feature with at least a `test.sh` script. The `devcontainer-cli features test <...>` [will execute tests of this form](https://github.com/devcontainers/features/blob/main/.github/workflows/test-all.yaml).
- [`test-scenarios`] - More complex scenarios involving a set of features from this repo. `devcontainer-cli features test --scenario <PATH>` [will execute tests of this form](https://github.com/devcontainers/features/blob/main/.github/workflows/test-scenarios.yaml)

## Usage

<!-- TODO -->

## Developing

### Contibuting to this repository

<!-- TODO -->

### Self-hosting your own collection of features

<!-- TODO -->
