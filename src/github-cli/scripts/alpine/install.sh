#!/usr/bin/env sh
# shellcheck shell=sh
#
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------
#
# Docs: https://github.com/devcontainers/features/tree/main/src/github-cli
# Maintainer: The VS Code and Codespaces Teams

set -eu

# shellcheck source-path=SCRIPTDIR source=../common.sh
. "${COMMON_UTILS}"

# Map Alpine's architecture names onto the ones used by the gh release assets
release_arch() {
  case "$(apk --print-arch)" in
  x86_64) echo "amd64" ;;
  aarch64) echo "arm64" ;;
  x86) echo "386" ;;
  armhf | armv7) echo "armv6" ;;
  *) echo "" ;;
  esac
}

download_release() {
  destination_dir="${1}"
  cli_filename="${2}"

  echo "Downloading ${cli_filename}..."
  wget -q -O "${destination_dir}/${cli_filename}" \
    "https://github.com/cli/cli/releases/download/v${CLI_VERSION}/${cli_filename}"
}

# Alpine has no equivalent of the `.deb` the Debian installer fetches, so use the
# statically linked tarball that the same release publishes
install_tarball_using_github() {
  arch="$(release_arch)"
  if [ -z "${arch}" ]; then
    {
      echo "(!) github-cli publishes no release asset for architecture $(apk --print-arch)."
      echo "(!) Set the 'installDirectlyFromGitHubRelease' option to false to install from Alpine's community repository instead."
    } >&2
    return 1
  fi

  find_version_from_git_tags CLI_VERSION

  tmp_dir="$(mktemp -d)"
  # shellcheck disable=SC2064 # expand now so the trap still knows the path on exit
  trap "rm -rf '${tmp_dir}'" EXIT

  cli_filename="gh_${CLI_VERSION}_linux_${arch}.tar.gz"
  if ! download_release "${tmp_dir}" "${cli_filename}"; then
    # Handle the situation where git tags are ahead of what is available to download
    echo "(!) github-cli version ${CLI_VERSION} failed to download. Attempting to fall back one version to retry..." >&2
    find_prev_version_from_git_tags CLI_VERSION
    cli_filename="gh_${CLI_VERSION}_linux_${arch}.tar.gz"
    download_release "${tmp_dir}" "${cli_filename}"
  fi

  tar -xzf "${tmp_dir}/${cli_filename}" -C "${tmp_dir}"
  extracted_dir="${tmp_dir}/gh_${CLI_VERSION}_linux_${arch}"

  # Install into /usr/bin rather than /usr/local/bin to match where the Debian package
  # lands: the `gh extension list` shim that install-extensions.sh may drop into
  # /usr/local/bin/gh execs /usr/bin/gh, and would otherwise recurse into itself.
  install -D -m 0755 "${extracted_dir}/bin/gh" /usr/bin/gh

  for manpage in "${extracted_dir}"/share/man/man1/*.1; do
    [ -f "${manpage}" ] || continue
    install -D -m 0644 "${manpage}" "/usr/share/man/man1/$(basename "${manpage}")"
  done
}

# The community repository is signed with the Alpine keys the base image already trusts,
# so none of the third-party keyring handling the Debian installer needs applies here
install_using_alpine_repository() {
  case "${CLI_VERSION}" in
  latest | current | lts | stable) ;;
  *)
    {
      echo "(*) Alpine's community repository carries a single github-cli version, so the requested version '${CLI_VERSION}' cannot be honoured and will be ignored."
      echo "(*) Leave the 'installDirectlyFromGitHubRelease' option at its default of true to pin a specific version."
    } >&2
    ;;
  esac

  apk add --update --no-cache --repository='http://dl-cdn.alpinelinux.org/alpine/edge/community' github-cli
}

# `apk add` is idempotent and skips anything already present, so there is no need for the
# "is it installed?" checks the dpkg-based installer has to make. gh shells out to git for
# most of what it does, so install it here as the Debian installer does.
apk add --no-cache ca-certificates git

# ../install-extensions.sh is a bash script, and bash is not part of the Alpine base image
if [ -n "${EXTENSIONS}" ]; then
  apk add --no-cache bash
fi

# Install the GitHub CLI
echo "Downloading github CLI..."

if [ "${INSTALL_DIRECTLY_FROM_GITHUB_RELEASE}" = "true" ]; then
  install_tarball_using_github
else
  install_using_alpine_repository
fi

echo "Done!"

# No clean up needed: `--no-cache` means apk never writes an index or package cache to disk.
