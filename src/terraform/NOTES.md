## Licensing

On August 10, 2023, HashiCorp announced a change of license for its products, including Terraform. After ~9 years of Terraform being open source under the MPL v2 license, it was to move under a non-open source BSL v1.1 license, starting from the next (1.6) version. See https://github.com/hashicorp/terraform/blob/main/LICENSE

## Custom Download Server

The `customDownloadServer` option allows you to specify an alternative server for downloading Terraform and Sentinel packages. This is useful for organizations that maintain internal mirrors or have proxies for HashiCorp downloads.

When using this option:
- Provide the complete URL including protocol (e.g., `https://my-mirror.example.com`)
- The server should mirror the HashiCorp releases structure
- For Sentinel with custom servers, specifying an exact version is recommended instead of "latest"

Example:
```json
"features": {
    "ghcr.io/devcontainers/features/terraform:1": {
        "customDownloadServer": "https://my-mirror.example.com"
    }
}
```

## OS Support

This Feature should work on recent versions of Debian/Ubuntu-based distributions with the `apt` package manager installed.

`bash` is required to execute the `install.sh` script.
