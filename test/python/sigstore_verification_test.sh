#!/usr/bin/env bash
set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
install_script="${INSTALL_SH:-${repository_root}/src/python/install.sh}"
work_dir="$(mktemp -d)"
trap 'rm -rf "${work_dir}"' EXIT
mkdir "${work_dir}/tmp"
export TMPDIR="${work_dir}/tmp"
export MOCK_LOG="${work_dir}/cosign-args"
export MOCK_REJECT="false"
mock_architecture="x86_64"
mock_download_failure=""
mock_checksum_failure="false"
download_log="${work_dir}/downloads"
checksum_log="${work_dir}/checksum"
COSIGN_PINNED_VERSION="3.1.4"
COSIGN_CACHE_DIR=""
COSIGN_LATEST_VERSION=""
COSIGN_LATEST_READY="false"
COSIGN_PINNED_BINARY=""
COSIGN_LATEST_BINARY=""
COSIGN_ACTIVE_BINARY=""

cat > "${work_dir}/cosign" <<'COSIGN'
#!/usr/bin/env bash
printf '%s\n' "$@" > "${MOCK_LOG}"
[[ "${MOCK_REJECT}" != "true" ]]
COSIGN
chmod 0755 "${work_dir}/cosign"

uname() {
    printf '%s\n' "${mock_architecture}"
}

sleep() { :; }

# Keep this test focused on the pinned-verifier path. The installer still
# calls the shared version resolver, so return the pinned version here.
find_version_from_git_tags() {
    local variable_name="$1"
    local requested_version="${!variable_name}"
    local fallback_version="${7:-3.1.4}"
    if [[ "${requested_version}" == "3" ]]; then
        printf -v "${variable_name}" '%s' "${fallback_version}"
    fi
    printf '%s=%s\n' "${variable_name}" "${!variable_name}"
}

curl() {
    local destination="" url=""
    while [[ $# -gt 0 ]]; do
        if [[ "$1" = "-o" ]]; then
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
    elif [[ "${url}" == *.sigstore ]]; then
        printf 'bundle\n' > "${destination}"
    else
        cp "${work_dir}/cosign" "${destination}"
    fi
}

sha256sum() {
    cat > "${checksum_log}"
    [[ "${mock_checksum_failure}" != "true" ]]
}

source <(sed -n '/^get_architecture() {$/,/^# GPG verification for python versions </ { /^# GPG verification for python versions /!p; }' "${install_script}")

cpython_tgz_filename="Python-3.14.10.tgz"
cpython_tgz_url="https://www.python.org/ftp/python/3.14.10/${cpython_tgz_filename}"
policy_url="https://www.python.org/downloads/metadata/sigstore/"

# The updated installer intentionally keeps this cache between Python
# installations. Clear it between independent test cases, not each call.
assert_clean() {
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

cosign_verification 3.14.10
grep -Fx -- "${policy_url}" "${download_log}"
grep -Fx -- 'https://github.com/sigstore/cosign/releases/download/v3.1.4/cosign-linux-amd64' "${download_log}"
grep -Fx -- "${cpython_tgz_url}.sigstore" "${download_log}"
grep -F -- '424e2c97d0b45fd7a6b608a87f090f35633f4c23ece5f092d48bba11aaf4bbfa' "${checksum_log}"
grep -Fx -- '--bundle' "${MOCK_LOG}"
grep -Fx -- '--certificate-identity' "${MOCK_LOG}"
grep -Fx -- 'hugo@python.org' "${MOCK_LOG}"
grep -Fx -- '--certificate-oidc-issuer' "${MOCK_LOG}"
grep -Fx -- 'https://github.com/login/oauth' "${MOCK_LOG}"
grep -Fx -- "/tmp/python-src/${cpython_tgz_filename}" "${MOCK_LOG}"

cosign_verification 3.15.0
grep -Fx -- 'hugo@python.org' "${MOCK_LOG}"
cosign_verification 3.16.0
grep -Fx -- 'savannah@python.org' "${MOCK_LOG}"
assert_clean

mock_architecture="armv7l"
cosign_verification 3.14.10
grep -Fx -- 'https://github.com/sigstore/cosign/releases/download/v3.1.4/cosign-linux-arm' "${download_log}"
grep -F -- '09e77a313910cf5c4774508d85d017d9c60983f41bf657f83ecbd3892f7952cb' "${checksum_log}"
assert_clean

export MOCK_REJECT="true"
if cosign_verification 3.14.10; then exit 1; fi
export MOCK_REJECT="false"
assert_clean

mock_checksum_failure="true"
if cosign_verification 3.14.10; then exit 1; fi
mock_checksum_failure="false"
assert_clean

mock_download_failure="/downloads/metadata/sigstore/"
if cosign_verification 3.14.10; then exit 1; fi
assert_clean
mock_download_failure=".sigstore"
if cosign_verification 3.14.10; then exit 1; fi
assert_clean
mock_download_failure="cosign-linux-arm"
if cosign_verification 3.14.10; then exit 1; fi
mock_download_failure=""
assert_clean

: > "${download_log}"
if cosign_verification 3.99.0; then exit 1; fi
grep -Fx -- "${policy_url}" "${download_log}"
if grep -E 'cosign-linux-|\.sigstore$' "${download_log}"; then exit 1; fi
assert_clean

: > "${download_log}"
mock_architecture="unsupported"
if cosign_verification 3.14.10; then exit 1; fi
[[ ! -s "${download_log}" ]]
assert_clean

printf 'Sigstore verification regression checks passed\n'