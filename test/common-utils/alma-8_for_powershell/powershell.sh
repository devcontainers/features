#!/usr/bin/env bash

dnf install -y wget
wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq && chmod +x /usr/bin/yq
dnf install -y krb5-libs libicu openssl-libs zlib
# Problem: conflicting requests
#   - nothing provides krb5 needed by powershell-7.5.0-1.cm.aarch64 from @commandline
latest_release=$(curl -s https://api.github.com/repos/PowerShell/PowerShell/releases/latest) && \
  sudo  rpmlink=$(echo "$latest_release" | arch=$(arch) yq -r '[.assets[] | select(.name == ("*" + strenv(arch) + ".rpm")) | .browser_download_url'][0]) && \
  sudo  dnf install -y $rpmlink