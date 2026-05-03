#!/usr/bin/env bash
# topics/00-system/install.sh: System prerequisites and base CLI utilities.

set -euo pipefail
# shellcheck source=SCRIPTDIR/../../lib/utils.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/utils.sh"

apt_update_once

# Prerequisites and commonly-used utilities
apt_install \
    build-essential \
    ca-certificates \
    curl \
    wget \
    git \
    gnupg \
    lsb-release \
    software-properties-common \
    apt-transport-https \
    pkg-config \
    unzip \
    zip \
    tar \
    rsync \
    htop \
    btop \
    tree \
    jq \
    ripgrep \
    fd-find \
    fzf \
    bat \
    tldr \
    net-tools \
    iputils-ping \
    dnsutils \
    locales \
    man-db \
    openssh-server \
    ufw

# Note: ufw is installed but NOT enabled. 
# To enable it manually:
#   sudo ufw default deny incoming
#   sudo ufw default allow outgoing
#   sudo ufw allow ssh                  # if you want incoming SSH
#   sudo ufw enable

# On Ubuntu, fdfind/batcat have non-standard names: create symlinks.
mkdir -p "$HOME/.local/bin"
[[ -x /usr/bin/fdfind && ! -e "$HOME/.local/bin/fd"  ]] && ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
[[ -x /usr/bin/batcat && ! -e "$HOME/.local/bin/bat" ]] && ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"

log_success "00-system: OK"
