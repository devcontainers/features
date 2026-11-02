

## OS Support

See [supportedPlatformVersions.md](https://github.com/microsoft/Oryx/blob/main/doc/supportedPlatformVersions.md) on the Oryx repository for supported platforms.  Notably, `oryx` does not support Debian "jammy".

`bash` is required to execute the `install.sh` script.

## Installation Footprint

Oryx applications are published self-contained into a shared directory, so they do not require a preinstalled .NET runtime. The build-only SDK and runtimes added by this Feature are removed after publishing; pre-existing .NET installations are preserved.

Only scripts and metadata used for dynamic SDK installation are retained from the Oryx source tree. Installer logs report disk usage before and after source cleanup.
