FROM ubuntu:noble

COPY meta.env /usr/local/etc/dev-containers/meta.env

RUN if id "ubuntu" &>/dev/null; then \
            echo "Deleting user 'ubuntu' for noble" && userdel -f -r ubuntu || echo "Failed to delete ubuntu user for noble"; \  
        else \
            echo "User 'ubuntu' does not exist for noble"; \ 
    fi
