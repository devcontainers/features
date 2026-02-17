FROM ubuntu:noble
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=100
RUN if ! getent group users > /dev/null 2>&1; then groupadd --gid $USER_GID users; fi \
    && if ! id -u $USERNAME > /dev/null 2>&1; then \
            if ! id -u $USER_UID > /dev/null 2>&1; then \
                useradd --uid $USER_UID --gid $USER_GID -m $USERNAME; \
            else \
                echo "UID $USER_UID already exists, creating user without specifying UID"; \
                useradd --gid $USER_GID -m $USERNAME; \
            fi; \
        fi