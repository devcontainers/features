
# Kubectl, Helm, and Minkube (kubectl-helm-minikube)

Installs latest version of kubectl, Helm, and optionally minikube. Auto-detects latest versions and installs needed dependencies.

## Example Usage

```json
"features": {
        "ghcr.io/devcontainers/features/kubectl-helm-minikube:1": {
            "version": "latest"
        }
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Select or enter a Kubernetes version to install | string | latest |
| helm | Select or enter a Helm version to install | string | latest |
| minikube | Select or enter a Minikube version to install | string | latest |

---

_Note: This file was auto-generated from the [devcontainer-feature.json](./devcontainer-feature.json)._
