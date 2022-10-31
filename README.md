# Development Container Features

<table style="width: 100%; border-style: none;"><tr>
<td style="width: 140px; text-align: center;"><a href="https://github.com/devcontainers"><img width="128px" src="https://raw.githubusercontent.com/microsoft/fluentui-system-icons/78c9587b995299d5bfc007a0077773556ecb0994/assets/Cube/SVG/ic_fluent_cube_32_filled.svg" alt="devcontainers organization logo"/></a></td>
<td>
<strong>Development Container 'Features'</strong><br />
<i>A set of simple and reusable Features. Quickly add a language/tool/CLI to a development container.
</td>
</tr></table>

'Features' are self-contained units of installation code and development container configuration. Features are designed
to install atop a wide-range of base container images (**this repo focuses on `debian` based images**).

Missing a CLI or language in your otherwise _perfect_ container image? Add the relevant Feature to the `features`
property of a [`devcontainer.json`](https://containers.dev/implementors/json_reference/#general-properties). A
[tool supporting the dev container specification](https://containers.dev/supporting) is required to build a development
container.

You may learn about Features at [containers.dev](https://containers.dev/implementors/features/), which is the website for the dev container specification.

## Usage

To reference a Feature from this repository, add the desired Features to a `devcontainer.json`. Each Feature has a `README.md` that shows how to reference the Feature and which options are available for that Feature.

The example below installs the `go` and `docker-in-docker` declared in the [`./src`](./src) directory of this
repository.

See the relevant Feature's README for supported options.

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
Feature. Features follow semantic versioning conventions, so you can pin to a major version `:1`, minor version `:1.0`, or patch version `:1.0.0` by specifying the appropriate label.

```jsonc
"features": {
    "ghcr.io/devcontainers/features/go:1.0.0": {
        "version": "1.18"
    }
}
```

The [devcontainer CLI reference implementation](https://github.com/devcontainers/cli) (or a
[supporting tool](https://containers.dev/supporting)) can be used to build a project's dev container declaring
Features.

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
│   ├── go
|   |   ├── scenarios.json
|   |   ├── test_scenario_1.json
│   |   └── test.sh
|   ├── ...
│   │   └── test.sh
...
```

-   [`src`](src) - A collection of subfolders, each declaring a Feature. Each subfolder contains at least a
    `devcontainer-feature.json` and an `install.sh` script.
-   [`test`](test) - Mirroring `src`, a folder-per-feature with at least a `test.sh` script. The
    [`devcontainer` CLI](https://github.com/devcontainers/cli) will execute
    [these tests in CI](https://github.com/devcontainers/features/blob/main/.github/workflows/test-all.yaml).

## Contributions

### Creating your own collection of Features

The [Feature distribution specification](https://containers.dev/implementors/features-distribution/) outlines a pattern for community members and organizations to self-author Features in repositories they control.

A template repo [`devcontainers/feature-template`](https://github.com/devcontainers/feature-template) and [GitHub Action](https://github.com/devcontainers/action) are available to help bootstrap self-authored Features.

We are eager to hear your feedback on self-authoring!  Please provide comments and feedback on [spec issue #70](https://github.com/devcontainers/spec/issues/70).

### Contributing to this repository

This repository will accept improvement and bug fix contributions related to the
[current set of maintained Features](./src).
