# Development Container Features

<table style="width: 100%; border-style: none;"><tr>
<td style="width: 140px; text-align: center;"><a href="https://github.com/devcontainers"><img width="128px" src="https://raw.githubusercontent.com/microsoft/fluentui-system-icons/78c9587b995299d5bfc007a0077773556ecb0994/assets/Cube/SVG/ic_fluent_cube_32_filled.svg" alt="devcontainers organization logo"/></a></td>
<td>
<strong>Development Container 'Features'</strong><br />
<i>A set of simple and reusable 'features'. Quickly add a language/tool/CLI to a development container.
</td>
</tr></table>

'Features' are self-contained units of installation code and development container configuration. Features are designed
to install atop a wide-range of base container images (**this repo focuses on `debian` based images**).

Missing a CLI or language in your otherwise _perfect_ container image? Add the relevant 'feature' to the `features`
property of a [`devcontainer.json`](https://containers.dev/implementors/json_reference/#general-properties). A
[tool supporting the dev container specification](https://containers.dev/supporting) is required to build a development
container.

⚠️ Development container 'features' are a
[**proposed**](https://github.com/devcontainers/spec/blob/main/proposals/devcontainer-features.md) addition to the
[development container specification](https://containers.dev/implementors/spec/). **Please note that 'features' are in
preview and subject to breaking changes**.

Once the [**proposed**](https://github.com/devcontainers/spec/blob/main/proposals/devcontainer-features.md)
specification is accepted, implementation details will be published at
[https://containers.dev](https://containers.dev/).


## Usage

To reference a feature from this repository, add the desired features to a `devcontainer.json`. Each feature has a `README.md` that shows how to reference the feature and which options are available for that feature.

The example below installs the `go` and `docker-in-docker` declared in the [`./src`](./src) directory of this
repository.

See the relevant feature's README for supported options.

```jsonc
"name": "my-project-devcontainer",
"image": "mcr.microsoft.com/devcontainers/base:ubuntu",  // Any generic, debian-based image.
"features": {
    "ghcr.io/devcontainers/features/go:1": {
        "version": "1.18"
    },
    "ghcr.io/devcontainers/features/docker-in-docker:1": {
        "version": "latest",
        "moby": true
    }
}
```

The `:latest` version annotation is added implicitly if omitted. To pin to a specific package version
([example](https://github.com/devcontainers/features/pkgs/container/features/go/versions)), append it to the end of the
feature. Features follow semantic versioning conventions, so you can pin to a major version `:1`, minor version `:1.0`, or patch version `:1.0.0` by specifying the appropriate label.

```jsonc
"features": {
    "ghcr.io/devcontainers/features/go:1.0.0": {
        "version": "1.18"
    }
}
```

The [devcontainer CLI reference implementation](https://github.com/devcontainers/cli) (or a
[supporting tool](https://containers.dev/supporting)) can be used to build a project's dev container declaring
'features'.

```bash
git clone <my-project-with-devcontainer>
devcontainer build --workspace-folder <path-to-my-project-with-devcontainer>
```

## Repo Structure

```
.
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

-   [`src`](src) - A collection of subfolders, each declaring a feature. Each subfolder contains at least a
    `devcontainer-feature.json` and an `install.sh` script.
-   [`test`](test) - Mirroring `src`, a folder-per-feature with at least a `test.sh` script. The
    [`devcontainer` CLI](https://github.com/devcontainers/cli) will execute
    [these tests in CI](https://github.com/devcontainers/features/blob/main/.github/workflows/test-all.yaml).
-   [`test-scenarios`](test-scenarios) - More complex scenarios involving a set of features from this repo. The
    [`devcontainer` CLI](https://github.com/devcontainers/cli) will execute
    [these tests in CI](https://github.com/devcontainers/features/blob/main/.github/workflows/test-scenarios.yaml).

## Contributions

### Creating your own collection of features

Please see the
[proposed specification](https://github.com/devcontainers/spec/blob/main/proposals/devcontainer-features-distribution.md)
on how to start to author and distribute features your own features.

We're excited for you to create features! Our team is actively iterating on tools and examples to help members of the
community author their own dev container features. If you have any feedback along the way, please let us know in the
specification repo's issues on [features](https://github.com/devcontainers/spec/issues/61) or
[feature distribution](https://github.com/devcontainers/spec/issues/70).

### Contributing to this repository

This repository will accept improvement and bug fix contributions related to the
[current set of maintained features](./src).
