# Common Helper Function Tests

This directory contains tests for the common-setup.sh helper function that is deployed to each feature.

## Structure

The `common-setup.sh` helper script is **not** shared from a central location. Instead, it's copied into each feature's `_lib/` directory:
- `src/anaconda/_lib/common-setup.sh`
- `src/docker-in-docker/_lib/common-setup.sh`
- etc.

This is because the devcontainer CLI packages each feature independently, and external directories are not included in the build context.

## Running Tests

```bash
bash test/_lib/test-common-setup.sh
```

The tests reference one of the feature copies (anaconda) as the source of truth for validation.

## Updating the Helper

If you need to update the helper function:

1. Update the source in any feature's `_lib/common-setup.sh`
2. Copy it to all other features' `_lib/` directories
3. Run the tests to verify functionality
4. Update all affected features' versions

Note: All copies should be kept in sync to ensure consistent behavior across features.
