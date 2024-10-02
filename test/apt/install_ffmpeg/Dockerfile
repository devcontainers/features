# Builds an image with a preconfigured SUDOERS file
# Used to test the install script for JupyterLab which modifies this file
FROM mcr.microsoft.com/devcontainers/base:debian

COPY --chown=vscode Aptfile.dev /tmp/dev-container-features/apt_0/Aptfile.dev
