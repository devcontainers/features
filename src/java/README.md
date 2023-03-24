
# Java (via SDKMAN!) (java)

Installs Java, SDKMAN! (if not installed), and needed dependencies.

## Example Usage

```json
"features": {
    "ghcr.io/devcontainers/features/java:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Select or enter a Java version to install | string | latest |
| jdkDistro | Select or enter a JDK distribution | string | ms |
| installGradle | Install Gradle, a build automation tool for multi-language software development | boolean | false |
| gradleVersion | Select or enter a Gradle version | string | latest |
| installMaven | Install Maven, a management tool for Java | boolean | false |
| mavenVersion | Select or enter a Maven version | string | latest |
| installAnt | Install Ant, a software tool for automating software build processes | boolean | false |
| antVersion | Select or enter an Ant version | string | latest |

## License

For the Java Feature from this repository, see [NOTICE.txt](https://github.com/devcontainers/features/tree/main/src/java/NOTICE.txt) for licensing information on JDK distributions.


## OS Support

This Feature should work on recent versions of Debian/Ubuntu-based distributions with the `apt` package manager installed.

`bash` is required to execute the `install.sh` script.


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/devcontainers/features/blob/main/src/java/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
