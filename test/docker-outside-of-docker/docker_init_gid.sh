#!/bin/bash

set -e

source dev-container-features-test-lib

test_gid_case() (
    set -e

    local scenario="$1"
    export GID_TEST_DIR
    GID_TEST_DIR="$(mktemp -d)"
    trap 'rm -rf "${GID_TEST_DIR}"' EXIT

    echo 2000 > "${GID_TEST_DIR}/docker-gid"
    echo 100 > "${GID_TEST_DIR}/socket-gid"
    touch "${GID_TEST_DIR}/source.sock" "${GID_TEST_DIR}/groups"
    ln -s "${GID_TEST_DIR}/source.sock" "${GID_TEST_DIR}/target.sock"

    sed -e "s|/var/run/docker-host.sock|${GID_TEST_DIR}/source.sock|g" \
        -e "s|/var/run/docker.sock|${GID_TEST_DIR}/target.sock|g" \
        -e "s|/tmp/vscr-docker-from-docker|${GID_TEST_DIR}/proxy|g" \
        /usr/local/share/docker-init.sh > "${GID_TEST_DIR}/docker-init.sh"

    getent() {
        if [ "$1" != group ]; then
            return 1
        fi
        if [ "$2" = docker ] || [ "$2" = "$(cat "${GID_TEST_DIR}/docker-gid")" ]; then
            echo "docker:x:$(cat "${GID_TEST_DIR}/docker-gid"):vscode"
        else
            awk -F: -v gid="$2" '$3 == gid { print; found = 1 } END { exit !found }' "${GID_TEST_DIR}/groups"
        fi
    }

    stat() {
        [ "$1" = -c ] && [ "$2" = '%g' ] && [ "$3" = "${GID_TEST_DIR}/source.sock" ]
        cat "${GID_TEST_DIR}/socket-gid"
    }

    groupmod() {
        [ "$1" = --gid ] && [ "$3" = docker ]
        echo "$2" > "${GID_TEST_DIR}/docker-gid"
        echo "$*" > "${GID_TEST_DIR}/groupmod"
    }

    id() {
        [ "$1" = -u ]
        echo 0
    }

    socat() {
        return 0
    }

    export -f getent stat groupmod id socat

    case "${scenario}" in
        matching|stale-target)
            echo 100 > "${GID_TEST_DIR}/docker-gid"
            if [ "${scenario}" = stale-target ]; then
                rm "${GID_TEST_DIR}/target.sock"
                touch "${GID_TEST_DIR}/target.sock"
            fi
            ;;
        prefix)
            echo 'other:x:1000:' > "${GID_TEST_DIR}/groups"
            ;;
        collision)
            echo 'other:x:100:' > "${GID_TEST_DIR}/groups"
            ;;
        *) return 1 ;;
    esac

    bash "${GID_TEST_DIR}/docker-init.sh" true || return 1

    case "${scenario}" in
        matching)
            [ -L "${GID_TEST_DIR}/target.sock" ] &&
            [ "$(readlink "${GID_TEST_DIR}/target.sock")" = "${GID_TEST_DIR}/source.sock" ] &&
            [ ! -e "${GID_TEST_DIR}/proxy.pid" ] &&
            [ ! -e "${GID_TEST_DIR}/groupmod" ] &&
            grep -q 'Docker group matches socket GID 100, nothing to do' "${GID_TEST_DIR}/proxy.log"
            ;;
        prefix)
            [ "$(cat "${GID_TEST_DIR}/docker-gid")" = 100 ] &&
            grep -qx -- '--gid 100 docker' "${GID_TEST_DIR}/groupmod" &&
            [ -L "${GID_TEST_DIR}/target.sock" ] &&
            [ ! -e "${GID_TEST_DIR}/proxy.pid" ]
            ;;
        collision|stale-target)
            [ ! -L "${GID_TEST_DIR}/target.sock" ] &&
            [ -s "${GID_TEST_DIR}/proxy.pid" ] &&
            [ ! -e "${GID_TEST_DIR}/groupmod" ] &&
            grep -q 'Enabling socket proxy.' "${GID_TEST_DIR}/proxy.log"
            ;;
    esac
)

check "runtime-matching-gid-preserves-symlink-without-proxy" test_gid_case matching
check "prefix-only-gid-match-updates-docker-group-without-proxy" test_gid_case prefix
check "exact-gid-collision-enables-proxy" test_gid_case collision
check "matching-gid-with-stale-target-enables-proxy" test_gid_case stale-target

reportResults
