
# Rust (rust)

Installs Rust, common Rust utilities, and their required dependencies

## Example Usage

```json
"features": {
    "ghcr.io/devcontainers/features/rust:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Select or enter a version of Rust to install. | string | latest |
| profile | Select a rustup install profile. | string | minimal |
| targets | Optional comma separated list of additional Rust targets to install. | string | - |
| components | Optional comma separeated list of rust components to be installed based on input. | string | rust-analyzer,rust-src,rustfmt,clippy |

## Customizations

### VS Code Extensions

- `vadimcn.vscode-lldb`
- `rust-lang.rust-analyzer`
- `tamasfe.even-better-toml`



## OS Support

This Feature should work on recent versions of Debian/Ubuntu, RedHat Enterprise Linux, Fedora, Alma, RockyLinux 
and Mariner distributions with the `apt`, `yum`, `dnf`, `microdnf` and `tdnf` package manager installed.


**Note:** Alpine is not supported because the rustup-init binary requires glibc to run, but Alpine Linux does not include `glibc` 
by default. Instead, it uses musl libc, which is not binary-compatible with glibc.

`bash` is required to execute the `install.sh` script.


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/devcontainers/features/blob/main/src/rust/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
