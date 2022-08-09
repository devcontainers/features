
# Python (python)

Installs the provided version of Python, as well as PIPX, and other common Python utilities.  JupyterLab is conditionally installed with the python feature. Note: May require source code compilation.

## Example Usage

```json
"features": {
        "ghcr.io/devcontainers/features/python:1": {
            "version": "latest"
        }
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Select a Python version to install. | string | os-provided |
| install_python_tools | Install common Python tools like pylint | boolean | true |
| optimize | Optimize Python for performance when compiled (slow) | boolean | - |
| installPath | The path where python will be installed. | string | /usr/local/python |
| override_default_version | If true, overrides existing version (if any) of python on the PATH | boolean | true |
| install_jupyterlab | Install JupyterLab, a web-based interactive development environment for notebooks | boolean | - |
| configure_jupyterlab_allow_origin | Configure JupyterLab to accept HTTP requests from the specified origin | string | - |

---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/devcontainers/features/blob/main/src/python/devcontainer-feature.json)._
