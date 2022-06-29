# Development Container Features

<table style="width: 100%; border-style: none;"><tr>
<td style="width: 140px; text-align: center;"><a href="https://github.com/devcontainers"><img width="128px" src="https://raw.githubusercontent.com/microsoft/fluentui-system-icons/78c9587b995299d5bfc007a0077773556ecb0994/assets/Cube/SVG/ic_fluent_cube_32_filled.svg" alt="devcontainers organization logo"/></a></td>
<td>
<strong>Development Container 'Features'</strong><br />
<i>A set of simple and reusable 'features'. Quickly add a language/tool/CLI to a development container.
</td>
</tr></table>

'Features' are self-contained units of installation code and development container configuration. Features are designed to install atop a wide-range of base container images (**this repo focuses on `debian` based images**).

Missing a CLI or language in your otherwise _perfect_ container image? Add the relevant 'feature' to the `features` property of a [`devcontainer.json`](https://containers.dev/implementors/json_reference/#general-properties).  A [tool supporting the dev container specification](https://containers.dev/supporting) is required to build a development container.

⚠️ Development container 'features' are a [**proposed**](https://github.com/devcontainers/spec/blob/main/proposals/devcontainer-features.md) addition to the [development container specification](https://github.com/devcontainers/spec/blob/main/proposals/devcontainer-features.md). **Please note that 'features' are in preview and subject to breaking changes**.

Once the [**proposed**](https://github.com/devcontainers/spec/blob/main/proposals/devcontainer-features.md) specification is accepted, implementation details will be published at [https://containers.dev](https://containers.dev/).


## Repo Structure

```
.
├── lib
|   ├── settings.env
|   ├── utils.sh
│   └── ...
├── README.md
├── src
│   ├── dotnet
│   │   ├── devcontainer-feature.json
│   │   └── install.sh
│   ├── go
│   │   ├── devcontainer-feature.json
│   │   └── install.sh
|   ├── ...
│   │   ├── devcontainer-feature.json
│   │   └── install.sh
├── test
│   ├── dotnet
│   │   └── test.sh
│   └── go
│   |   └── test.sh
|   ├── ...
│   │   └── test.sh
├── test-scenarios
│   ├── install_jupyterlab.sh
│   ├── install_python_twice.sh
|   ├── ...
│   └── scenarios.json
```

- [`lib`](lib) - A collection of tools, scripts, and shared configuration used generally by this repo's features.
- [`src`](src) - A collection of subfolders, each declaring a feature. Each subfolder contains at least a `devcontainer-feature.json` and the appropriately declared install script.
- [`test`](test) - Mirroring `src`, a folder-per-feature with at least a `test.sh` script. The [`devcontainer` CLI](https://github.com/devcontainers/cli) will execute [these tests in CI](https://github.com/devcontainers/features/blob/main/.github/workflows/test-all.yaml).
- [`test-scenarios`](test-scenarios) - More complex scenarios involving a set of features from this repo. The [`devcontainer` CLI](https://github.com/devcontainers/cli) will execute [these tests in CI](https://github.com/devcontainers/features/blob/main/.github/workflows/test-scenarios.yaml).

## Usage

To reference a feature from this repository, add the desired features to a `devcontainer.json`.

The example below installs the `go` and `docker-in-docker` declared in the [`./src`](./src) directory of this repository.

See the relevant feature's README for supported options.

```jsonc
"name": "my-project-devcontainer",
"image": "mcr.microsoft.com/devcontainers/base:ubuntu",  // Any generic, debian-based image.
features: {
    "devcontainers/features/go@latest": {
        "version": "1.18"
    },
    "devcontainers/features/docker-in-docker@latest": {
        "version": "latest",
        "moby": true
    }
}
```

The `@latest` version annotation is added implicitly if omitted. To pin to a specific [release tag](https://github.com/devcontainers/features/releases), append it to the end of the feature.

```jsonc
features: {
    "devcontainers/features/go@v0.0.2": {
        "version": "1.18"
    },
```

The [devcontainer CLI reference implementation](https://github.com/devcontainers/cli) (or a [supporting tool](https://containers.dev/supporting)) can be used to build a project's dev container declaring 'features'.

```bash
git clone <my-project-with-devcontainer>
devcontainer build --workspace-folder <path-to-my-project-with-devcontainer>
```

## Contributions

### Contibuting to this repository

This repository will accept improvement and bug fix contributions related to the [current set of maintained features](./src).

### Creating your own collection of features

_More information your creating own set of features will be posted soon._
