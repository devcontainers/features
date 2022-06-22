# Development Container Features

'Features' wrap self-contained units of installation code that applies pre-determined configuration on top of a dev container's image.  A 'feature' is added to the `features` property of a [`devcontainer.json`](https://containers.dev/implementors/json_reference/#general-properties).

Development container 'features' are a [proposed](https://github.com/devcontainers/spec/blob/main/proposals/devcontainer-features.md) addition to the [development container specification](https://github.com/devcontainers/spec/blob/main/proposals/devcontainer-features.md).  **Please note that 'features' are in preview and subject to breaking changes**.


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
├── test
│   ├── dotnet
│   │   └── test.sh
│   └── go
│       └── test.sh
```
