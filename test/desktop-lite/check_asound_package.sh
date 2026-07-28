checkOSPackage() {
    PACKAGE_NAME=$1
    # Check if the package exists and retrieve its exact version
    if [ "$(dpkg-query -W -f='${Status}' "$PACKAGE_NAME" 2>/dev/null | grep -c "ok installed")" -eq 1 ]; then
        echo "✅  Package '$PACKAGE_NAME' is installed."
        return 0
    else
        echo "❌ Package '$PACKAGE_NAME' is not installed."
        return 1
    fi
}

findAvailableOSPackage() {
    local candidate
    local package_name
    for package_name in "$@"; do
        candidate="$(apt-cache policy "${package_name}" | awk '/Candidate:/ {print $2}')"
        if [ -n "${candidate}" ] && [ "${candidate}" != "(none)" ]; then
            echo "${package_name}"
            return 0
        fi
    done
    return 1
}

checkAsoundPackage() {
    local alsa_package
    if ! alsa_package="$(findAvailableOSPackage libasound2 libasound2t64 libasound2-dev)"; then
        echo "No supported ALSA package found in apt indexes." >&2
        exit 1
    fi
    check "alsa-package-installed-${alsa_package}" checkOSPackage "${alsa_package}"
}
