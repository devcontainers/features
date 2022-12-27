## Ingress and port forwarding

When configuring [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/) for your Kubernetes cluster, note that by default Kubernetes will bind to a specific interface's IP rather than localhost or all interfaces. This is why you need to use the Kubernetes Node's IP when connecting - even if there's only one Node as in the case of Minikube. Port forwarding in Remote - Containers will allow you to specify `<ip>:<port>` in either the `forwardPorts` property or through the port forwarding UI in VS Code.

However, GitHub Codespaces does not yet support this capability, so you'll need to use `kubectl` to forward the port to localhost. This adds minimal overhead since everything is on the same machine. E.g.:

```bash
minikube start
minikube addons enable ingress
# Run this to forward to localhost in the background
nohup kubectl port-forward --pod-running-timeout=24h -n ingress-nginx service/ingress-nginx-controller :80 &
```


## OS Support

This Feature should work on recent versions of Debian/Ubuntu-based distributions with the `apt` package manager installed.

`bash` is required to execute the `install.sh` script.
