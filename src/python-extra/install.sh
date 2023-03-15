set -e
USERNAME="${USERNAME:-"${_REMOTE_USER:-"automatic"}"}"
PYTHON_SRC=$(which python)

sudo_if() {
    COMMAND="$*"
    if [ "$(id -u)" -eq 0 ] && [ "$USERNAME" != "root" ]; then
        su - "$USERNAME" -c "$COMMAND"
    else
        "$COMMAND"
    fi
}

install_user_package() {
    PACKAGE="$1"
    sudo_if "${PYTHON_SRC}" -m pip install --user --upgrade --no-cache-dir "$PACKAGE"
}

install_user_package pylint
install_user_package flake8
install_user_package black

echo "Done!"
