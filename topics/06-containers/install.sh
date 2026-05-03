#!/usr/bin/env bash
# topics/06-containers/install.sh: Docker (official repo) + Distrobox.

set -euo pipefail
# shellcheck source=SCRIPTDIR/../../lib/utils.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/utils.sh"

# Docker via the official repository
if ! command_exists docker; then
    log_info "Installing Docker (official repo)"
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
        | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    # shellcheck disable=SC1091
    . /etc/os-release
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${VERSION_CODENAME} stable" \
        | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

    sudo apt-get update -qq
    apt_install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    if ! id -nG "$USER" | grep -qw docker; then
        sudo usermod -aG docker "$USER"
        log_warn "Added to docker group — re-login required."
    fi
fi

# Distrobox: useful to isolate cross-toolchains in containers
if ! command_exists distrobox; then
    log_info "Installing Distrobox"
    curl -fsSL https://raw.githubusercontent.com/89luca89/distrobox/main/install | sudo sh
fi

log_success "06-containers: OK"
