## OS Support

This Feature should work on recent versions of Debian/Ubuntu-based distributions with the `apt` package manager installed.

`bash` is required to execute the `install.sh` script.

## Authentication

If you set the `authOnSetup` option, the feature installs a one-time shell startup hook script. When `gh auth status` shows you are not already authenticated, the hook first tries `gh auth login --with-token` if `GH_TOKEN` or `GITHUB_TOKEN` is available in the environment, otherwise it falls back to `gh auth login` in an interactive shell. This happens after the dev container starts, so it can use values injected through runtime environment settings like `remoteEnv`.

Example:

```json
{
	"features": {
		"ghcr.io/devcontainers/features/github-cli:1": {
			"authOnSetup": true,
			"extensions": "dlvhdr/gh-dash,github/gh-copilot"
		}
	},
	"remoteEnv": {
		"GITHUB_TOKEN": "${localEnv:GITHUB_TOKEN}"
	}
}
```

If you already authenticate on the host with GitHub CLI, export a token before opening the dev container:

```bash
export GITHUB_TOKEN="$(gh auth token)"
```

Then the `remoteEnv` example above will pass that token into the container's post-start auth flow.

## Extensions

If you set the `extensions` option, the feature requires either `authOnSetup=true` or `installExtensionsFromGit=true`. The unsupported combination `authOnSetup=false` and `installExtensionsFromGit=false` fails during feature setup with a clear error.

When `authOnSetup=true`, extension installation is deferred until that post-start auth flow runs so runtime tokens can be used for authenticated installs, unless `installExtensionsFromGit=true`. Extensions are installed for the most appropriate non-root user (based on `USERNAME` / `_REMOTE_USER`), with a fallback to `root`.

Set `installExtensionsFromGit` to `true` if you want to skip `gh extension install` and always clone extension repositories directly. In that mode, extensions install during feature setup even when `authOnSetup` is enabled.
