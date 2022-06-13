
# Python (may require compilation) (python)

Python (may require compilation)

## Example Usage

```json
"features": [
    "python": {
        "id": "devcontainers/features/#{featureId}@latest",
        "options": {
            "version": "latest"
        }
    }
]
```

## Options

| Options Id | Description | Type | Default Value ||-----|-----|-----|-----|
| version | Select a Python version to install. | string | os-provided |
| install_python_tools | Install common Python tools like pylint | boolean | true |
| optimize | Optimize Python for performance when compiled (slow) | boolean | - |
| installPath | The path where python will be installed. | string | /usr/local/python |
| override_default_version | If true, overrides existing version (if any) of python on the PATH | boolean | true |
| install_jupyterlab | Install JupyterLab, a web-based interactive development environment for notebooks | boolean | - |
| configure_jupyterlab_allow_origin | Configure JupyterLab to accept HTTP requests from the specified origin | string | - |

---

_Note: This is an auto-generated file. Please do not directly edit._
