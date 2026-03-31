# Shared Code Maintenance

This document explains how shared code is maintained across features in this repository.

## Problem

Multiple features need the same helper functions (e.g., user selection logic). The devcontainer specification currently packages each feature independently and doesn't support sharing code between features at runtime.

## Solution

We maintain a **single source of truth** with a **CI-time sync mechanism** to deploy to each feature:

### Single Source
- **Location**: `scripts/lib/common-setup.sh`
- **Contains**: Shared helper functions (currently user selection logic)
- **Maintenance**: All updates happen here

### Deployment
- **Mechanism**: `scripts/sync-common-setup.sh` (runs automatically in CI)
- **Target**: Copies to each feature's directory as `common-setup.sh` at build/test time
- **Reason**: Devcontainer packaging requires files to be within each feature's directory
- **Note**: The copies are `.gitignore`d — only the source file is tracked in git

## Workflow

### Making Changes

1. **Edit the source**: Modify `scripts/lib/common-setup.sh`
2. **Test**: Run `bash test/_global/test-common-setup.sh`
3. **Commit**: Only the source file needs to be committed

```bash
# Edit the source
vim scripts/lib/common-setup.sh

# Test
bash test/_global/test-common-setup.sh

# Commit just the source
git add scripts/lib/common-setup.sh
git commit -m "Update common-setup.sh helper function"
```

### Local Development

To generate the copies locally (e.g., for testing features outside CI):

```bash
./scripts/sync-common-setup.sh
```

### CI Integration

All CI workflows (test, release, stress test) automatically run `sync-common-setup.sh`
after checkout and before the devcontainer CLI packages features. This ensures the
copies are always present and up-to-date without tracking them in git.

## Why Not Use Shared Files?

The devcontainer CLI packages each feature independently. When a feature is installed:

1. Only files within the feature's directory are included in the package
2. Parent directories (`../common`) are not accessible
3. Hidden directories (`.common`) are excluded from packaging
4. Sibling feature directories are not accessible

This is a design decision in the devcontainer specification to ensure features are portable and self-contained.

## Future

The devcontainer spec has a proposal for an `include` property in `devcontainer-feature.json` ([spec#129](https://github.com/devcontainers/spec/issues/129)) that would enable native code sharing. Once implemented, the sync mechanism can be removed in favor of declarative includes:

```json
{
  "id": "my-feature",
  "include": ["../../scripts/lib/common-setup.sh"]
}
```

## Current Implementation

As of this PR:
- **Source**: `scripts/lib/common-setup.sh` (87 lines)
- **Deployed**: 16 features, each with `src/FEATURE/common-setup.sh` (generated at CI time, gitignored)
- **Sync Script**: `scripts/sync-common-setup.sh` (called by all CI workflows)
- **Tests**: `test/_global/test-common-setup.sh` (14 test cases)
- **Benefits**: Eliminated ~188 lines of inline duplicated logic from install scripts, zero duplicate files tracked in git

## References

- [Devcontainer Spec Issue #129 - Share code between features](https://github.com/devcontainers/spec/issues/129)
- [Features Library Proposal](https://github.com/devcontainers/spec/blob/main/proposals/features-library.md)
- Test documentation: `test/_global/test-common-setup.sh`
- Sync script documentation: `scripts/README.md`
