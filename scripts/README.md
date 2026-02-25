# Shared Feature Code

This directory contains code that is shared across multiple features.

## Structure

```
scripts/
├── lib/
│   └── common-setup.sh         # Source of truth for user selection helper
└── sync-common-setup.sh         # Script to deploy helper to all features
```

## Maintenance

### The Source of Truth

**`scripts/lib/common-setup.sh`** is the single source of truth for the user selection helper function. All modifications should be made to this file.

### Deploying Changes

Due to the devcontainer CLI's packaging behavior (each feature is packaged independently), the helper must be deployed to each feature's `_lib/` directory. We maintain this through a sync script:

```bash
./scripts/sync-common-setup.sh
```

This copies `scripts/lib/common-setup.sh` to all features:
- `src/anaconda/_lib/common-setup.sh`
- `src/docker-in-docker/_lib/common-setup.sh`
- etc.

### Workflow

1. **Edit**: Make changes to `scripts/lib/common-setup.sh`
2. **Test**: Run `bash test/_lib/test-common-setup.sh` to verify
3. **Sync**: Run `./scripts/sync-common-setup.sh` to deploy to all features
4. **Commit**: Commit both the source and all copies together

### Why Copies?

The devcontainer CLI packages each feature independently:
- Parent directories are not included in the build context
- Hidden directories (`.common`) are not included
- Sibling directories are not accessible

Therefore, each feature needs its own copy of the helper to ensure it's available at runtime during feature installation.

## Testing

Tests are located in `test/_lib/` and reference the anaconda feature's copy as the source:

```bash
bash test/_lib/test-common-setup.sh
```

## Future

This approach is a workaround for the current limitation. The devcontainer spec has a proposal for an `include` property in `devcontainer-feature.json` that would allow native code sharing (see [devcontainers/spec#129](https://github.com/devcontainers/spec/issues/129)). Once implemented, this sync mechanism can be removed.
