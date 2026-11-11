#!/usr/bin/env bash
set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
install_script="${INSTALL_SH:-${repository_root}/src/python/install.sh}"
work_dir="$(mktemp -d)"
trap 'rm -rf "${work_dir}"' EXIT
mkdir -p "${work_dir}/tmp"
export TMPDIR="${work_dir}/tmp"
export MOCK_LOG="${work_dir}/cosign-args"
export MOCK_CALLS="${work_dir}/cosign-calls"
export MOCK_REJECT="false"
export MOCK_REJECT_LATEST="false"
export MOCK_REJECT_RELEASE="false"
mock_architecture="x86_64"
mock_download_failure=""
mock_checksum_failure="false"
mock_resolved_version="3.1.4"
mock_resolver_failure="false"
download_log="${work_dir}/downloads"
checksum_log="${work_dir}/checksum"
COSIGN_PINNED_VERSION="3.1.4"
COSIGN_LAST_KNOWN_VERSION="${COSIGN_PINNED_VERSION}"
COSIGN_CACHE_DIR=""
COSIGN_LATEST_VERSION=""
COSIGN_LATEST_READY="false"
COSIGN_PINNED_BINARY=""
COSIGN_LATEST_BINARY=""
COSIGN_ACTIVE_BINARY=""

cat > "${work_dir}/cosign" <<'COSIGN'
#!/usr/bin/env bash
printf '%s\n' "$@" > "${MOCK_LOG}"
printf '%s|%s\n' "$(basename "$0")" "$*" >> "${MOCK_CALLS}"
if [[ "$*" == *'keyless@projectsigstore.iam.gserviceaccount.com'* ]]; then
    [[ "${MOCK_REJECT_RELEASE}" != "true" ]]
elif [[ "$(basename "$0")" == cosign-3.2.0-* ]]; then
    [[ "${MOCK_REJECT_LATEST}" != "true" && "${MOCK_REJECT}" != "true" ]]
else
    [[ "${MOCK_REJECT}" != "true" ]]
fi
COSIGN
chmod 0755 "${work_dir}/cosign"

uname() { printf '%s\n' "${mock_architecture}"; }
sleep() { :; }

find_version_from_git_tags() {
    local variable_name="$1"
    [[ "${7:-}" == "${COSIGN_LAST_KNOWN_VERSION}" ]] || return 1
    [[ "${mock_resolver_failure}" != "true" ]] || return 1
    printf '%s=%s\n' "${variable_name}" "${mock_resolved_version}"
}

curl() {
    local destination="" url=""
    while [[ $# -gt 0 ]]; do
        if [[ "$1" == "-o" ]]; then
            destination="$2"
            shift 2
        else
            url="$1"
            shift
        fi
    done
    printf '%s\n' "${url}" >> "${download_log}"
    if [[ -n "${mock_download_failure}" && "${url}" == *"${mock_download_failure}"* ]]; then
        return 22
    fi
    if [[ "${url}" == */downloads/metadata/sigstore/ ]]; then
        cat > "${destination}" <<'POLICY'
<table>
<thead><tr><th>Release</th><th>PEP</th><th>Release manager</th><th>OIDC Issuer</th></tr></thead>
<tbody>
<tr><td>3.14</td><td>PEP 745</td><td><code>hugo@python.org</code></td><td><code>https://github.com/login/oauth</code></td></tr>
<tr><td>3.15</td><td>PEP 790</td><td><code>hugo@python.org</code></td><td><code>https://github.com/login/oauth</code></td></tr>
<tr><td>3.16</td><td>PEP 826</td><td><code>savannah@python.org</code></td><td><code>https://github.com/login/oauth</code></td></tr>
</tbody>
</table>
POLICY
    elif [[ "${url}" == *.sigstore || "${url}" == *.sigstore.json ]]; then
        printf 'bundle\n' > "${destination}"
    else
        cp "${work_dir}/cosign" "${destination}"
    fi
}

sha256sum() {
    cat >> "${checksum_log}"
    [[ "${mock_checksum_failure}" != "true" ]]
}

# Stop at the GPG function itself, independent of the preceding comment's case.
helper_functions="$(awk '
    /^get_architecture\(\)[[:space:]]*\{[[:space:]]*$/ { copying = 1 }
    copying && /^gpg_verification\(\)[[:space:]]*\{[[:space:]]*$/ { exit }
    copying { print }
' "${install_script}")"

[[ "${helper_functions}" == *'cosign_verification() {'* ]] || {
    echo "Failed to extract Sigstore helpers from ${install_script}" >&2
    exit 1
}

source /dev/stdin <<< "${helper_functions}"

cpython_tgz_filename="Python-3.14.10.tgz"
cpython_tgz_url="https://www.python.org/ftp/python/3.14.10/${cpython_tgz_filename}"
policy_url="https://www.python.org/downloads/metadata/sigstore/"

reset_cache() {
    if [[ -n "${COSIGN_CACHE_DIR}" && -d "${COSIGN_CACHE_DIR}" ]]; then
        rm -rf -- "${COSIGN_CACHE_DIR}"
    fi
    COSIGN_CACHE_DIR=""
    COSIGN_LATEST_VERSION=""
    COSIGN_LATEST_READY="false"
    COSIGN_PINNED_BINARY=""
    COSIGN_LATEST_BINARY=""
    COSIGN_ACTIVE_BINARY=""
    [[ -z "$(find "${TMPDIR}" -mindepth 1 -print -quit)" ]]
}
assert_downloaded() { grep -Fqx -- "$1" "${download_log}"; }
assert_called() { grep -Fq -- "$1" "${MOCK_CALLS}"; }

# Pinned verifier: signer selection, arguments, checksum, and cache reuse.
cosign_verification 3.14.10
assert_downloaded "${policy_url}"
assert_downloaded 'https://github.com/sigstore/cosign/releases/download/v3.1.4/cosign-linux-amd64'
assert_downloaded "${cpython_tgz_url}.sigstore"
grep -Fq -- '424e2c97d0b45fd7a6b608a87f090f35633f4c23ece5f092d48bba11aaf4bbfa' "${checksum_log}"
grep -Fxq -- 'hugo@python.org' "${MOCK_LOG}"
grep -Fxq -- 'https://github.com/login/oauth' "${MOCK_LOG}"
cosign_verification 3.15.0
grep -Fxq -- 'hugo@python.org' "${MOCK_LOG}"
cosign_verification 3.16.0
grep -Fxq -- 'savannah@python.org' "${MOCK_LOG}"
[[ "$(grep -Fc -- "${policy_url}" "${download_log}")" -eq 1 ]]
[[ "$(grep -Fc -- '/v3.1.4/cosign-linux-amd64' "${download_log}")" -eq 1 ]]
reset_cache

mock_architecture="armv7l"
cosign_verification 3.14.10
assert_downloaded 'https://github.com/sigstore/cosign/releases/download/v3.1.4/cosign-linux-arm'
grep -Fq -- '09e77a313910cf5c4774508d85d017d9c60983f41bf657f83ecbd3892f7952cb' "${checksum_log}"
reset_cache
mock_architecture="x86_64"

export MOCK_REJECT="true"
if cosign_verification 3.14.10; then exit 1; fi
export MOCK_REJECT="false"
reset_cache

mock_checksum_failure="true"
if cosign_verification 3.14.10; then exit 1; fi
mock_checksum_failure="false"
reset_cache

mock_download_failure="/downloads/metadata/sigstore/"
if cosign_verification 3.14.10; then exit 1; fi
reset_cache
mock_download_failure=".sigstore"
if cosign_verification 3.14.10; then exit 1; fi
reset_cache
mock_download_failure="cosign-linux-amd64"
if cosign_verification 3.14.10; then exit 1; fi
mock_download_failure=""
reset_cache

: > "${download_log}"
if cosign_verification 3.99.0; then exit 1; fi
assert_downloaded "${policy_url}"
if grep -Eq 'cosign-linux-|\.sigstore$' "${download_log}"; then exit 1; fi
reset_cache

: > "${download_log}"
mock_architecture="unsupported"
if cosign_verification 3.14.10; then exit 1; fi
[[ ! -s "${download_log}" ]]
reset_cache
mock_architecture="x86_64"

# Promote a newer Cosign only after pinned Cosign verifies its Sigstore bundle.
mock_resolved_version="3.2.0"
: > "${MOCK_CALLS}"
: > "${download_log}"
cosign_verification 3.14.10
assert_downloaded 'https://github.com/sigstore/cosign/releases/download/v3.2.0/cosign-linux-amd64'
assert_downloaded 'https://github.com/sigstore/cosign/releases/download/v3.2.0/cosign-linux-amd64.sigstore.json'
assert_called 'cosign-3.1.4-amd64|verify-blob'
assert_called 'keyless@projectsigstore.iam.gserviceaccount.com'
assert_called 'https://accounts.google.com'
assert_called 'cosign-3.2.0-amd64|verify-blob'
[[ "${COSIGN_ACTIVE_BINARY}" == *'/cosign-3.2.0-amd64' ]]
reset_cache

# Reject an unauthenticated newer Cosign binary; continue with the pinned one.
export MOCK_REJECT_RELEASE="true"
: > "${MOCK_CALLS}"
cosign_verification 3.14.10
[[ "${COSIGN_ACTIVE_BINARY}" == "${COSIGN_PINNED_BINARY}" ]]
assert_called 'keyless@projectsigstore.iam.gserviceaccount.com'
if grep -Fq 'cosign-3.2.0-amd64|verify-blob' "${MOCK_CALLS}"; then exit 1; fi
export MOCK_REJECT_RELEASE="false"
reset_cache

# Newer verifier rejects Python; pinned verifier retries successfully.
export MOCK_REJECT_LATEST="true"
: > "${MOCK_CALLS}"
cosign_verification 3.14.10
assert_called 'cosign-3.2.0-amd64|verify-blob'
assert_called 'cosign-3.1.4-amd64|verify-blob'
export MOCK_REJECT_LATEST="false"
reset_cache

# Both verifiers reject Python; verification must fail.
export MOCK_REJECT="true"
if cosign_verification 3.14.10; then exit 1; fi
export MOCK_REJECT="false"
reset_cache

# Newer release download or bundle download fails; pinned remains usable.
mock_download_failure="/v3.2.0/cosign-linux-amd64.sigstore.json"
cosign_verification 3.14.10
[[ "${COSIGN_ACTIVE_BINARY}" == "${COSIGN_PINNED_BINARY}" ]]
mock_download_failure=""
reset_cache

# Newer executable download fails; pinned remains usable.
mock_download_failure="/v3.2.0/cosign-linux-amd64"
cosign_verification 3.14.10
[[ "${COSIGN_ACTIVE_BINARY}" == "${COSIGN_PINNED_BINARY}" ]]
mock_download_failure=""
reset_cache

# Invalid major-version resolution must not promote an unsupported verifier.
mock_resolved_version="4.0.0"
cosign_verification 3.14.10
[[ "${COSIGN_ACTIVE_BINARY}" == "${COSIGN_PINNED_BINARY}" ]]
mock_resolved_version="3.2.0"
reset_cache

# Tag lookup failure must retain the pinned trusted verifier.
mock_resolver_failure="true"
cosign_verification 3.14.10
[[ "${COSIGN_ACTIVE_BINARY}" == "${COSIGN_PINNED_BINARY}" ]]
mock_resolver_failure="false"
reset_cache

printf 'Sigstore verification regression checks passed\n'