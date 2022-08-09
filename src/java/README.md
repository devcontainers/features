
# Java (via SDKMAN!) (java)

Installs Java, SDKMAN! (if not installed), and needed dependencies.

## Example Usage

```json
"features": {
        "ghcr.io/devcontainers/features/java:1": {
            "version": "latest"
        }
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Select or enter a Java version to install | string | lts |
| install_gradle | Install Gradle, a build automation tool for multi-language software development | boolean | - |
| install_maven | Install Maven, a management tool for Java | boolean | - |

---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/devcontainers/features/blob/main/src/java/devcontainer-feature.json)._
