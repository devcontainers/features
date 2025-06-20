#!/usr/bin/env bash
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------
#
# Docs: https://github.com/microsoft/vscode-dev-containers/blob/main/script-library/docs/anaconda.md
# Maintainer: The VS Code and Codespaces Teams


# Initialize environment variables with defaults
initialize_environment() {
    VERSION="${VERSION:-"latest"}"
    USERNAME="${USERNAME:-"${_REMOTE_USER:-"automatic"}"}"
    UPDATE_RC="${UPDATE_RC:-"true"}"
    CONDA_DIR="${CONDA_DIR:-"/usr/local/conda"}"
    
    # Map camelCase options to uppercase environment variables 
    # for backwards compatibility with internal script logic
    USE_CONDA_FORGE="${useCondaForge:-"true"}"
    INSTALL_MAMBA="${installMamba:-"true"}"
    USE_SYSTEM_PACKAGES="${useSystemPackages:-"true"}"
    INSTALL_FULL_ANACONDA="${installFullAnaconda:-"false"}"
    
    # Ensure boolean values are properly set
    if [ "${INSTALL_MAMBA}" = "false" ] || [ "${INSTALL_MAMBA}" = "False" ] || [ "${INSTALL_MAMBA}" = "0" ]; then
        INSTALL_MAMBA="false"
    else
        INSTALL_MAMBA="true"
    fi
    
    if [ "${USE_CONDA_FORGE}" = "false" ] || [ "${USE_CONDA_FORGE}" = "False" ] || [ "${USE_CONDA_FORGE}" = "0" ]; then
        USE_CONDA_FORGE="false"
    else
        USE_CONDA_FORGE="true"
    fi
    
    if [ "${USE_SYSTEM_PACKAGES}" = "false" ] || [ "${USE_SYSTEM_PACKAGES}" = "False" ] || [ "${USE_SYSTEM_PACKAGES}" = "0" ]; then
        USE_SYSTEM_PACKAGES="false"
    else
        USE_SYSTEM_PACKAGES="true"
    fi
    
    if [ "${INSTALL_FULL_ANACONDA}" = "false" ] || [ "${INSTALL_FULL_ANACONDA}" = "False" ] || [ "${INSTALL_FULL_ANACONDA}" = "0" ]; then
        INSTALL_FULL_ANACONDA="false"
    else
        INSTALL_FULL_ANACONDA="true"
    fi
    
    echo "Configuration options:"
    echo "- VERSION: ${VERSION}"
    echo "- USE_CONDA_FORGE: ${USE_CONDA_FORGE}"
    echo "- INSTALL_MAMBA: ${INSTALL_MAMBA}"
    echo "- USE_SYSTEM_PACKAGES: ${USE_SYSTEM_PACKAGES}"
    echo "- INSTALL_FULL_ANACONDA: ${INSTALL_FULL_ANACONDA}"
    
    set -eux
    
    # Determine architecture - use dpkg if available, otherwise use uname
    if type dpkg >/dev/null 2>&1; then
        architecture=$(dpkg --print-architecture)
    else
        architecture="$(uname -m)"
        case "${architecture}" in
            x86_64) architecture="amd64" ;;
            aarch64) architecture="arm64" ;;
        esac
    fi
    
    # Convert architecture to Anaconda format
    case "${architecture}" in 
        amd64) architecture="x86_64" ;; 
        arm64) architecture="aarch64" ;; 
        *) 
            echo "Anaconda does not support machine architecture '$architecture'. Please use an x86-64 or ARM64 machine." 
            exit 1 
        ;;
    esac
    
    # Determine package manager
    package_manager=""
    if type apt >/dev/null 2>&1; then
        package_manager="apt"
    elif type apt-get >/dev/null 2>&1; then
        package_manager="apt-get"
    elif type dnf >/dev/null 2>&1; then
        package_manager="dnf"
    elif type yum >/dev/null 2>&1; then
        package_manager="yum"
    elif type zypper >/dev/null 2>&1; then
        package_manager="zypper"
    elif type apk >/dev/null 2>&1; then
        package_manager="apk"
    fi
    
    echo "Detected architecture: ${architecture}"
    echo "Detected package manager: ${package_manager:-none}"
    
    # Clean up any existing package lists
    rm -rf /var/lib/apt/lists/*
}

# Verify the script is run as root
ensure_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
        exit 1
    fi
}

# Setup the environment path for login shells
setup_environment_path() {
    rm -f /etc/profile.d/00-restore-env.sh
    echo "export PATH=${PATH//$(sh -lc 'echo $PATH')/\$PATH}" > /etc/profile.d/00-restore-env.sh
    chmod +x /etc/profile.d/00-restore-env.sh
}

# Determine the appropriate non-root user
resolve_username() {
    local resolved_username=""
    
    if [ "${USERNAME}" = "auto" ] || [ "${USERNAME}" = "automatic" ]; then
        possible_users=("vscode" "node" "codespace" "$(awk -v val=1000 -F ":" '$3==val{print $1}' /etc/passwd)")
        for current_user in "${possible_users[@]}"; do
            if id -u "${current_user}" > /dev/null 2>&1; then
                resolved_username="${current_user}"
                break
            fi
        done
        if [ "${resolved_username}" = "" ]; then
            resolved_username=root
        fi
    elif [ "${USERNAME}" = "none" ] || ! id -u ${USERNAME} > /dev/null 2>&1; then
        resolved_username=root
    else
        resolved_username="${USERNAME}"
    fi
    
    echo "${resolved_username}"
}

# Detect platform type for optimized installation
detect_platform() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        ID=$ID
        
        # Check if we're on Debian or Ubuntu
        if [[ "$OS" == *"Debian"* ]] || [[ "$OS" == *"Ubuntu"* ]] || [ "$ID" = "debian" ] || [ "$ID" = "ubuntu" ]; then
            echo "debian_based"
        elif [ "$ID" = "fedora" ] || [ "$ID" = "rhel" ] || [ "$ID" = "centos" ] || [ "$ID" = "rocky" ] || [ "$ID" = "almalinux" ]; then
            echo "redhat_based"
        elif [ "$ID" = "alpine" ]; then
            echo "alpine_based"
        elif [ "$ID" = "opensuse-leap" ] || [ "$ID" = "opensuse-tumbleweed" ] || [ "$ID" = "sles" ]; then
            echo "suse_based"
        else
            echo "generic"
        fi
    else
        echo "generic"
    fi
}

# Function to run commands as a specific user safely
run_as_user() {
    local user="$1"
    local cmd="$2"
    
    # Skip running as a different user if we're already that user
    if [ "$(id -u)" = "$(id -u $user)" ]; then
        bash -c "$cmd"
        return $?
    fi
    
    # Try different methods to run as user
    if command -v su >/dev/null 2>&1; then
        # Use su if available
        su --login -c "$cmd" "$user"
    elif command -v runuser >/dev/null 2>&1; then
        # Use runuser if available (more common on RHEL/CentOS/Fedora)
        runuser -l "$user" -c "$cmd"
    elif command -v sudo >/dev/null 2>&1; then
        # Use sudo if available
        sudo -u "$user" bash -c "$cmd"
    else
        # If no user switching tool is available, just run as current user
        echo "Warning: Unable to run command as user $user - running as current user instead"
        bash -c "$cmd"
    fi
    
    return $?
}

# Update shell rc files with provided content
update_rc_files() {
    local content="$1"
    
    if [ "${UPDATE_RC}" = "true" ]; then
        if [ -f /etc/bash.bashrc ] && [[ "$(cat /etc/bash.bashrc)" != *"$content"* ]]; then
            echo -e "$content" >> /etc/bash.bashrc
        fi
        if [ -f "/etc/zsh/zshrc" ] && [[ "$(cat /etc/zsh/zshrc)" != *"$content"* ]]; then
            echo -e "$content" >> /etc/zsh/zshrc
        fi
        # For systems that don't have these files
        if [ ! -f /etc/bash.bashrc ] && [ -f /etc/bashrc ]; then
            if [[ "$(cat /etc/bashrc)" != *"$content"* ]]; then
                echo -e "$content" >> /etc/bashrc
            fi
        fi
    fi
}

# Install required system packages using the appropriate package manager
install_required_packages() {
    local packages=("$@")
    
    case "$package_manager" in
        apt)
            # For Debian/Ubuntu with modern apt
            if ! dpkg -s "${packages[@]}" > /dev/null 2>&1; then
                if [ "$(find /var/lib/apt/lists/* 2>/dev/null | wc -l)" = "0" ]; then
                    apt update -y
                fi
                apt -y install --no-install-recommends "${packages[@]}"
            fi
            ;;
        apt-get)
            # For older Debian/Ubuntu
            if ! dpkg -s "${packages[@]}" > /dev/null 2>&1; then
                if [ "$(find /var/lib/apt/lists/* 2>/dev/null | wc -l)" = "0" ]; then
                    apt-get update -y
                fi
                apt-get -y install --no-install-recommends "${packages[@]}"
            fi
            ;;
        dnf)
            # For Fedora/RHEL/CentOS 8+
            dnf -y install "${packages[@]}"
            ;;
        yum)
            # For older RHEL/CentOS
            yum -y install "${packages[@]}"
            ;;
        zypper)
            # For openSUSE/SLES
            zypper -n install "${packages[@]}"
            ;;
        apk)
            # For Alpine
            apk add --no-cache "${packages[@]}"
            ;;
        *)
            echo "WARNING: Unsupported package manager. Manual installation of requirements needed."
            # Try to continue without installing packages
            ;;
    esac
}

# Prepare the conda directory with proper permissions
prepare_conda_directory() {
    local resolved_username="$1"
    
    if ! cat /etc/group | grep -e "^conda:" > /dev/null 2>&1; then
        groupadd -r conda
    fi
    usermod -a -G conda "${resolved_username}"

    mkdir -p $CONDA_DIR
    chown -R "${resolved_username}:conda" "${CONDA_DIR}"
    chmod -R g+r+w "${CONDA_DIR}"
    
    find "${CONDA_DIR}" -type d -print0 | xargs -n 1 -0 chmod g+s
}

# Install base Conda using the system's package manager (Debian/Ubuntu)
install_conda_debian() {
    local resolved_username="$1"
    
    echo "Installing Conda via system package manager..."
    
    # Add the repository keys
    install_required_packages curl ca-certificates gnupg2
    curl -sS https://repo.anaconda.com/pkgs/misc/gpgkeys/anaconda.asc | gpg --dearmor > /usr/share/keyrings/conda-archive-keyring.gpg
    
    # Add conda repository
    echo "deb [arch=${architecture} signed-by=/usr/share/keyrings/conda-archive-keyring.gpg] https://repo.anaconda.com/pkgs/misc/debrepo/conda stable main" > /etc/apt/sources.list.d/conda.list
    
    # Use appropriate apt command based on what's available
    if [ "$package_manager" = "apt" ]; then
        apt update -y
    else
        apt-get update -y
    fi
    
    # Install conda package
    local conda_pkg="conda"
    if [ "${VERSION}" != "latest" ] && [ "${VERSION}" != "lts" ]; then
        conda_pkg="conda=${VERSION}-0"
    fi
    
    if [ "$package_manager" = "apt" ]; then
        if apt -y install --no-install-recommends $conda_pkg; then
            setup_conda_after_debian_install "$resolved_username"
            return 0
        else
            echo "Falling back to direct installation..."
            return 1
        fi
    else
        if apt-get -y install --no-install-recommends $conda_pkg; then
            setup_conda_after_debian_install "$resolved_username"
            return 0
        else
            echo "Falling back to direct installation..."
            return 1
        fi
    fi
}

# Helper function to set up conda after Debian installation
setup_conda_after_debian_install() {
    local resolved_username="$1"
    
    # Set up conda properly
    local debian_conda_dir="/opt/conda"
    
    # Create a symlink if CONDA_DIR is different from the default
    if [ "$debian_conda_dir" != "$CONDA_DIR" ]; then
        ln -sf $debian_conda_dir $CONDA_DIR
    fi
    
    # First add the directory to the PATH so that we can access conda
    export PATH="$debian_conda_dir/bin:$PATH"
    
    # Check if the conda command is accessible now
    if command -v conda >/dev/null 2>&1; then
        # Initialize for the user using the direct path
        run_as_user "$resolved_username" "${debian_conda_dir}/bin/conda init bash"
        if [ -f "/etc/zsh/zshrc" ]; then
            run_as_user "$resolved_username" "${debian_conda_dir}/bin/conda init zsh"
        fi
        
        # Set CONDA_SCRIPT environment variable to help with testing
        echo "export CONDA_SCRIPT=\"${debian_conda_dir}/etc/profile.d/conda.sh\"" > /etc/profile.d/02-conda-script.sh
        chmod +x /etc/profile.d/02-conda-script.sh
        export CONDA_SCRIPT="${debian_conda_dir}/etc/profile.d/conda.sh"
        
        return 0
    else
        echo "Conda command not found after installation. Falling back to direct installation."
        return 1
    fi
}

# Install the minimal Conda distribution (Miniconda)
install_miniconda() {
    local resolved_username="$1"
    
    echo "Installing Miniconda..."
    
    # Download the installer directly as root
    export http_proxy=${http_proxy:-}
    export https_proxy=${https_proxy:-}
    wget -q https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-${architecture}.sh -O /tmp/miniconda-install.sh
    
    # Run the installer script
    bash /tmp/miniconda-install.sh -u -b -p ${CONDA_DIR}
    
    # Fix permissions
    chown -R "${resolved_username}:conda" "${CONDA_DIR}"
    
    # Initialize conda for both bash and zsh
    run_as_user "$resolved_username" "${CONDA_DIR}/bin/conda init bash"
    if [ -f "/etc/zsh/zshrc" ]; then
        run_as_user "$resolved_username" "${CONDA_DIR}/bin/conda init zsh"
    fi
    
    # Update conda to the latest version
    PATH=$PATH:${CONDA_DIR}/bin
    conda update -y conda
    
    # Set CONDA_SCRIPT environment variable to help with testing
    echo "export CONDA_SCRIPT=\"${CONDA_DIR}/etc/profile.d/conda.sh\"" > /etc/profile.d/02-conda-script.sh
    chmod +x /etc/profile.d/02-conda-script.sh
    export CONDA_SCRIPT="${CONDA_DIR}/etc/profile.d/conda.sh"
    
    rm /tmp/miniconda-install.sh
}

# Install the full Anaconda distribution
install_anaconda() {
    local resolved_username="$1"
    local version="$2"
    
    local anaconda_version=$version
    if [ "${version}" = "latest" ] || [ "${version}" = "lts" ]; then
        # Use the latest version if "latest" is specified for Anaconda
        anaconda_version="2024.10-1"
    fi
    
    echo "Installing full Anaconda distribution..."
    
    # Download the installer directly as root
    export http_proxy=${http_proxy:-}
    export https_proxy=${https_proxy:-}
    wget -q https://repo.anaconda.com/archive/Anaconda3-${anaconda_version}-Linux-${architecture}.sh -O /tmp/anaconda-install.sh
    
    # Run the installer script
    bash /tmp/anaconda-install.sh -u -b -p ${CONDA_DIR}
    
    # Fix permissions
    chown -R "${resolved_username}:conda" "${CONDA_DIR}"
    
    # Initialize conda for both bash and zsh
    run_as_user "$resolved_username" "${CONDA_DIR}/bin/conda init bash"
    if [ -f "/etc/zsh/zshrc" ]; then
        run_as_user "$resolved_username" "${CONDA_DIR}/bin/conda init zsh"
    fi
    
    # Update conda to the latest version if we're using "latest"
    if [ "${version}" = "latest" ] || [ "${version}" = "lts" ]; then
        PATH=$PATH:${CONDA_DIR}/bin
        conda update -y conda
    fi
    
    # Set CONDA_SCRIPT environment variable to help with testing
    echo "export CONDA_SCRIPT=\"${CONDA_DIR}/etc/profile.d/conda.sh\"" > /etc/profile.d/02-conda-script.sh
    chmod +x /etc/profile.d/02-conda-script.sh
    export CONDA_SCRIPT="${CONDA_DIR}/etc/profile.d/conda.sh"
    
    rm /tmp/anaconda-install.sh
}

# Configure conda with appropriate settings including channels
configure_conda() {
    echo "Configuring conda..."
    
    # Add both possible Conda paths to ensure we can find the binary
    export PATH="/opt/conda/bin:${CONDA_DIR}/bin:$PATH"
    
    # First check if conda is available
    if ! command -v conda >/dev/null 2>&1; then
        echo "Warning: conda command not found, configuration skipped"
        return 1
    fi
    
    # Set environment prompt format
    conda config --set env_prompt '({name})'
    
    # Configure conda-forge channel if requested
    if [ "${USE_CONDA_FORGE}" = "true" ]; then
        echo "Setting up conda-forge as the default channel..."
        conda config --add channels conda-forge
        conda config --set channel_priority strict
    fi
    
    # Configure conda to use libmamba solver for better performance
    # Note: This does NOT install mamba itself, just configures the solver if mamba is installed
    if [ "${INSTALL_MAMBA}" = "true" ]; then
        echo "Setting libmamba as the default solver for conda..."
        conda config --set solver libmamba
    fi
}

# Install mamba for faster package management
install_mamba() {
    echo "Installing mamba for faster package management..."
    
    # Add both possible Conda paths to ensure we can find the binary
    export PATH="/opt/conda/bin:${CONDA_DIR}/bin:$PATH"
    
    # Check if conda is available
    if ! command -v conda >/dev/null 2>&1; then
        echo "Warning: conda command not found, mamba installation skipped"
        return 1
    fi
    
    conda install -y -c conda-forge mamba
    
    # Add helpful aliases to make it easy to use either conda or mamba
    update_rc_files "# Mamba aliases for faster package management\nalias conda-fast='mamba'\nalias cf='mamba'"
}

# Setup conda configuration and shell integration
setup_conda_shell_integration() {
    # Add conda to path in RC files
    update_rc_files "export PATH=\$PATH:${CONDA_DIR}/bin"
    update_rc_files "export CONDA_DIR=${CONDA_DIR}"
    
    # Set up automatic environment activation
    update_rc_files "if [ -f \"${CONDA_DIR}/etc/profile.d/conda.sh\" ]; then . \"${CONDA_DIR}/etc/profile.d/conda.sh\"; fi"
    
    # Add useful conda aliases
    update_rc_files "# Useful conda aliases\nalias ca='conda activate'\nalias cda='conda deactivate'\nalias cen='conda env list'\nalias cre='conda env create -f'"
}

# Create notice about conda licensing for non-Codespaces environments
create_conda_notice() {
    local using_conda_forge="$1"
    
    mkdir -p /usr/local/etc/vscode-dev-containers
    
    if [ "${using_conda_forge}" = "true" ]; then
        cat << 'EOF' > /usr/local/etc/vscode-dev-containers/conda-notice.txt
When using "conda" from outside of GitHub Codespaces, note the Anaconda repository contains
restrictions on commercial use that may impact certain organizations. See https://aka.ms/ghcs-conda

Note: This container is using conda-forge as the default channel, which has more
permissive licensing than the default Anaconda repository.
EOF
    else
        cat << 'EOF' > /usr/local/etc/vscode-dev-containers/conda-notice.txt
When using "conda" from outside of GitHub Codespaces, note the Anaconda repository contains
restrictions on commercial use that may impact certain organizations. See https://aka.ms/ghcs-conda
EOF
    fi

    notice_script="$(cat << 'EOF'
if [ -t 1 ] && [ "${IGNORE_NOTICE}" != "true" ] && [ "${TERM_PROGRAM}" = "vscode" ] && [ "${CODESPACES}" != "true" ] && [ ! -f "$HOME/.config/vscode-dev-containers/conda-notice-already-displayed" ]; then
    cat "/usr/local/etc/vscode-dev-containers/conda-notice.txt"
    mkdir -p "$HOME/.config/vscode-dev-containers"
    ((sleep 10s; touch "$HOME/.config/vscode-dev-containers/conda-notice-already-displayed") &)
fi
EOF
)"

    if [ -f "/etc/zsh/zshrc" ]; then
        echo "${notice_script}" | tee -a /etc/zsh/zshrc
    fi

    if [ -f "/etc/bash.bashrc" ]; then
        echo "${notice_script}" | tee -a /etc/bash.bashrc
    fi
    
    # Handle different shell configurations in different distributions
    if [ ! -f /etc/bash.bashrc ] && [ -f /etc/bashrc ]; then
        echo "${notice_script}" | tee -a /etc/bashrc
    fi
}

# Clean up the system after installation
cleanup_system() {
    # Clean up based on the package manager
    case "$package_manager" in
        apt)
            apt clean
            rm -rf /var/lib/apt/lists/*
            ;;
        apt-get)
            apt-get clean
            rm -rf /var/lib/apt/lists/*
            ;;
        dnf)
            dnf clean all
            ;;
        yum)
            yum clean all
            ;;
        zypper)
            zypper clean -a
            ;;
        apk)
            # No cleanup needed for apk
            ;;
    esac
    
    echo "Done!"
}

# Main function to orchestrate the installation process
main() {
    initialize_environment
    ensure_root
    setup_environment_path
    
    local resolved_username=$(resolve_username)
    local platform=$(detect_platform)
    
    # Install dependencies based on the platform
    case "$platform" in
        debian_based)
            # Set Debian frontend to noninteractive for Debian/Ubuntu
            export DEBIAN_FRONTEND=noninteractive
            install_required_packages wget curl ca-certificates gnupg2
            ;;
        redhat_based)
            install_required_packages wget curl ca-certificates gnupg2
            ;;
        alpine_based)
            install_required_packages wget curl ca-certificates gnupg
            ;;
        suse_based)
            install_required_packages wget curl ca-certificates gnupg2
            ;;
        *)
            # Try a basic set of packages that might work
            install_required_packages wget curl ca-certificates gnupg2 || true
            ;;
    esac
    
    prepare_conda_directory "${resolved_username}"
    
    # Install conda if it's not already installed
    if ! command -v conda &> /dev/null; then
        # Try to use system packages on Debian/Ubuntu if USE_SYSTEM_PACKAGES is true
        if [ "$platform" = "debian_based" ] && [ "${USE_SYSTEM_PACKAGES}" = "true" ]; then
            if install_conda_debian "${resolved_username}"; then
                # Successfully installed using Debian package manager
                echo "Conda installed via system package manager."
            else
                # Fall back to direct installation
                if [ "${INSTALL_FULL_ANACONDA}" = "true" ]; then
                    # Install full Anaconda if requested
                    install_anaconda "${resolved_username}" "${VERSION}"
                else
                    # Otherwise install Miniconda (minimal installation)
                    install_miniconda "${resolved_username}"
                fi
            fi
        else
            # Direct installation for non-Debian/Ubuntu or when USE_SYSTEM_PACKAGES is false
            if [ "${INSTALL_FULL_ANACONDA}" = "true" ]; then
                # Install full Anaconda if requested
                install_anaconda "${resolved_username}" "${VERSION}"
            else
                # Otherwise install Miniconda (minimal installation)
                install_miniconda "${resolved_username}"
            fi
        fi
        
        # Configure the newly installed conda
        configure_conda
        setup_conda_shell_integration
    else
        echo "Conda is already installed."
        # Configure the existing conda
        configure_conda
    fi
    
    # Install mamba if requested - only install if INSTALL_MAMBA is true
    if [ "${INSTALL_MAMBA}" = "true" ]; then
        echo "Installing mamba (installMamba=${INSTALL_MAMBA})..."
        install_mamba
    else
        echo "Skipping mamba installation (installMamba=${INSTALL_MAMBA})..."
    fi
    
    create_conda_notice "${USE_CONDA_FORGE}"
    cleanup_system
}

# Execute the main function
main
