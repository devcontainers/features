sudo_if() {
    COMMAND="$*"
    if [ "$(id -u)" -eq 0 ] && [ "$USERNAME" != "root" ]; then
        su - "$USERNAME" -c "$COMMAND"
    else
        $COMMAND
    fi
}

install_python_package() {
    INSTALL_UNDER_ROOT="$1"
    PYTHON_PATH="$2"
    PACKAGE="$3"
    VERSION="${4:-""}"

    sudo_if "$PYTHON_PATH" -m pip uninstall --yes "$PACKAGE"

    install_package="${PACKAGE}"

    if [ ! -z "${VERSION}" ]; then
      install_package+="==${VERSION}"
    fi

    if [ "$INSTALL_UNDER_ROOT" = true ]; then
        sudo_if "$PYTHON_PATH" -m pip install --upgrade --no-cache-dir "$install_package"
    else
        sudo_if "$PYTHON_PATH" -m pip install --upgrade --user --no-cache-dir "$install_package"
    fi

    sudo_if "$PYTHON_PATH" -m pip --no-python-version-warning show "$PACKAGE"
}
