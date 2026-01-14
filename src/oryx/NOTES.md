

## OS Support

See [supportedPlatformVersions.md](https://github.com/microsoft/Oryx/blob/main/doc/supportedPlatformVersions.md) on the Oryx repository for supported platforms.  Notably, `oryx` does not support Debian "jammy".

`bash` is required to execute the `install.sh` script.

## Pinned Oryx Commit

The Oryx repository is pinned to commit `689fdef61a38802f1e1deda40be5933cc75e3631` (2026-01-13) to avoid a breaking change introduced in commit `21c559437d69cb43fd9b34f01f68c43ea4bce318` that added a `GetFileSize` method to `ISourceRepo` without updating the `MemorySourceRepo` test mock implementation, causing compilation failures.

This pin should be reviewed periodically and updated once the upstream issue is resolved.
