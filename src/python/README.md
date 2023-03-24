
# Python (python)

Installs the provided version of Python, as well as PIPX, and other common Python utilities.  JupyterLab is conditionally installed with the python feature. Note: May require source code compilation.

## Example Usage

```json
"features": {
    "ghcr.io/braechnov/features/python:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Select a Python version to install. | string | os-provided |
| installTools | Install common Python tools like pylint | boolean | true |
| optimize | Optimize Python for performance when compiled (slow) | boolean | false |
| installPath | The path where python will be installed. | string | /usr/local/python |
| installJupyterlab | Install JupyterLab, a web-based interactive development environment for notebooks | boolean | false |
| configureJupyterlabAllowOrigin | Configure JupyterLab to accept HTTP requests from the specified origin | string | - |



## OS Support

This Feature should work on recent versions of Debian/Ubuntu-based distributions with the `apt` package manager installed.

`bash` is required to execute the `install.sh` script.


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/braechnov/features/blob/main/src/python/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
