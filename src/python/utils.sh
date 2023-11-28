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

    sudo_if "$PYTHON_PATH -m pip uninstall --yes $PACKAGE"

    install_command=" -m pip install --upgrade --no-cache-dir "

    if [ "$INSTALL_UNDER_ROOT" = false ]; then
        install_command+="--user "
    fi

    install_command+="${PACKAGE}"

    if [ ! -z "${VERSION}" ]; then
      install_command+="==${VERSION}"
    fi

    sudo_if "$PYTHON_PATH$install_command"

    sudo_if "$PYTHON_PATH -m pip --no-python-version-warning show $PACKAGE"
}
