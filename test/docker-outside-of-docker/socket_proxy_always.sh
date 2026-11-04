#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# This script runs in a fresh process, which always gets up-to-date supplementary groups, so it
# cannot show whether the container's own command (started before the entrypoint finished) can use
# the socket. Take that command's groups instead and run docker with exactly those.
INIT_PID="$(pgrep -u "$(id -u)" -f '[C]ontainer started' | head -n 1)"
INIT_GROUPS="$(awk '/^Groups:/ {$1=""; print}' "/proc/${INIT_PID}/status" | xargs | tr ' ' ',')"
DOCKER_BIN="$(command -v docker)"

echo "container command pid: ${INIT_PID}, its groups: ${INIT_GROUPS}"

check "container-command-found" bash -c "[ -n '${INIT_PID}' ]"
check "docker-socket-is-proxy" bash -c "[ -S /var/run/docker.sock ] && [ ! -L /var/run/docker.sock ]"
check "socat-proxy-running" bash -c "pgrep -af 'socat UNIX-LISTEN:/var/run/docker.sock.*UNIX-CONNECT:/var/run/docker-host.sock'"
check "log-contents-for-proxy" bash -c "grep 'Enabling socket proxy' /tmp/vscr-docker-from-docker.log"
check "docker-ps" bash -c "docker ps >/dev/null"
check "docker-ps-with-container-command-groups" bash -c "sudo setpriv --reuid '$(id -u)' --regid '$(id -g)' --groups '${INIT_GROUPS}' env HOME=/tmp '${DOCKER_BIN}' ps >/dev/null"

# Deterministic check of the proxy selection. Whether the host socket's GID would pick `groupmod` depends
# on the host (GID 0 or a GID already in the image picks the proxy anyway), so build a fixture instead:
# a socket owned by an unused, nonzero GID that forwards to the real socket. The host socket is untouched.
FIXTURE_GID=4242
FIXTURE_DIR=/tmp/socket-proxy-fixture
DOCKER_GID_BEFORE="$(getent group docker | cut -d: -f3)"

check "fixture-gid-unused" bash -c "! getent group ${FIXTURE_GID}"

sudo mkdir -p "${FIXTURE_DIR}"
sudo chmod 777 "${FIXTURE_DIR}"
sudo socat "UNIX-LISTEN:${FIXTURE_DIR}/host.sock,fork,mode=660" UNIX-CONNECT:/var/run/docker-host.sock >/dev/null 2>&1 &
for _ in $(seq 1 50); do [ -S "${FIXTURE_DIR}/host.sock" ] && break; sleep 0.1; done
check "fixture-socket-created" bash -c "[ -S '${FIXTURE_DIR}/host.sock' ]"
sudo chown "root:${FIXTURE_GID}" "${FIXTURE_DIR}/host.sock"

# Run a copy of the generated docker-init.sh against the fixture. $1 = name, $2 = value of the
# option's baked-in condition ("true" as generated, "false" to emulate the default).
run_init_copy() {
    local dir="${FIXTURE_DIR}/$1"
    mkdir -p "${dir}"
    sed -e "s#/tmp/vscr-docker-from-docker#${dir}/vscr#g" \
        -e "s#/var/run/docker-host.sock#${FIXTURE_DIR}/host.sock#g" \
        -e "s#/var/run/docker.sock#${dir}/docker.sock#g" \
        -e "s#\[ \"true\" != \"true\" \]#[ \"$2\" != \"true\" ]#" \
        /usr/local/share/docker-init.sh > "${dir}/init.sh"
    chmod +x "${dir}/init.sh"
    "${dir}/init.sh" true
}

run_init_copy option-on true
check "option-on-selects-proxy" bash -c "grep 'Enabling socket proxy' '${FIXTURE_DIR}/option-on/vscr.log'"
check "option-on-docker-gid-unchanged" bash -c "[ \"\$(getent group docker | cut -d: -f3)\" = '${DOCKER_GID_BEFORE}' ]"
check "option-on-socket-owned-by-user" bash -c "[ \"\$(stat -c %U '${FIXTURE_DIR}/option-on/docker.sock')\" = \"\$(id -un)\" ]"
check "option-on-docker-ps-via-fixture-proxy" bash -c "docker -H 'unix://${FIXTURE_DIR}/option-on/docker.sock' ps >/dev/null"

# Control, run last because it changes the docker group: with the condition off, this fixture takes
# the groupmod path. If it did not, the checks above would not prove anything.
check "control-condition-present-in-generated-script" bash -c "grep -qF '[ \"true\" != \"true\" ]' /usr/local/share/docker-init.sh"
run_init_copy option-off false
check "control-selects-groupmod" bash -c "[ \"\$(getent group docker | cut -d: -f3)\" = '${FIXTURE_GID}' ]"
check "control-does-not-start-proxy" bash -c "! grep 'Enabling socket proxy' '${FIXTURE_DIR}/option-off/vscr.log'"

# Report result
reportResults
