#!/bin/bash
#
# Regression test for devcontainers/features#1639 / PR #1645 follow-up:
# verifies that when the dev container's root filesystem is overlayfs
# (the default under Docker / containerd-backed hosts), the standalone
# containerd started by the docker-in-docker Feature does NOT place its
# overlayfs snapshotter data on an overlay rootfs (which would fail with
# `invalid argument` when pulling images).
#
set -e

source dev-container-features-test-lib

# 1. Confirm we're really reproducing the affected condition:
#    the dev container's / must be overlay.
check "rootfs is overlay (precondition)" \
    bash -c '[ "$(findmnt -no FSTYPE /)" = "overlay" ]'

# 2. The Feature's volume mount must shadow /var/lib/containerd with a
#    non-overlay filesystem. Without the mount, containerd's overlayfs
#    snapshotter would be writing onto the overlay rootfs and fail at
#    pull time.
check "/var/lib/containerd is not overlay" \
    bash -c '[ "$(findmnt -no FSTYPE /var/lib/containerd)" != "overlay" ]'

check "/var/lib/docker is not overlay" \
    bash -c '[ "$(findmnt -no FSTYPE /var/lib/docker)" != "overlay" ]'

# 3. The actual symptom: pulling and running an image must succeed.
#    Pre-PR-#1645 this fails with:
#      failed to mount /tmp/containerd-mountXXXXX ... err: invalid argument
check "docker run hello-world" \
    docker run --rm hello-world

# 4. Belt-and-braces: confirm dockerd is actually using the
#    containerd-snapshotter path so we know this test exercises the
#    affected code path, not the legacy overlay2 driver.
check "containerd-snapshotter active" \
    bash -c "docker info 2>/dev/null | grep -qiE 'driver-type: io.containerd.snapshotter.v1|Storage Driver: overlayfs'"

reportResults

