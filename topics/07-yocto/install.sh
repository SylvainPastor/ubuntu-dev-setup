#!/usr/bin/env bash
# topics/07-yocto/install.sh: Host dependencies for Yocto development.
#
# Official reference:
# https://docs.yoctoproject.org/ref-manual/system-requirements.html

set -euo pipefail
# shellcheck source=SCRIPTDIR/../../lib/utils.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/utils.sh"

# ─── Official host dependencies (Ubuntu 22.04+) ──────────────────────────
# List taken from "Required Packages for the Build Host" — Yocto Reference
# Manual. Keep in sync with the Yocto release you target.
apt_install \
    gawk \
    wget \
    git \
    diffstat \
    unzip \
    texinfo \
    gcc \
    build-essential \
    chrpath \
    socat \
    cpio \
    python3 \
    python3-pip \
    python3-pexpect \
    xz-utils \
    debianutils \
    iputils-ping \
    python3-git \
    python3-jinja2 \
    python3-subunit \
    zstd \
    liblz4-tool \
    file \
    locales \
    libacl1

# ─── Yocto documentation (optional — uncomment to build docs) ────────────
# apt_install make xsltproc docbook-utils fop dblatex xmlto

# ─── QEMU for runqemu and image testing ──────────────────────────────────
apt_install \
    qemu-system-x86 \
    qemu-system-arm \
    qemu-system-aarch64 \
    qemu-user-static \
    qemu-utils

# ─── Image and flash tools ───────────────────────────────────────────────
apt_install \
    bmap-tools \
    mtools \
    dosfstools \
    parted \
    u-boot-tools \
    device-tree-compiler

# ─── Build performance ───────────────────────────────────────────────────
# ccache cuts rebuild times by 3-5×. Enable in local.conf with:
#   INHERIT += "ccache"
apt_install ccache

# ─── en_US.UTF-8 locale (required by bitbake) ────────────────────────────
# Without this locale, some do_package tasks fail silently.
if ! locale -a 2>/dev/null | grep -qiE '^en_US\.utf-?8$'; then
    log_info "Generating en_US.UTF-8 locale"
    sudo sed -i 's/^# *\(en_US\.UTF-8 UTF-8\)/\1/' /etc/locale.gen
    sudo locale-gen en_US.UTF-8
fi

# ─── repo (Google) — multi-repo management via XML manifest ──────────────
# Used by many BSPs (e.g. NXP, Xilinx) to fetch poky + meta-* from a
# single, consistent manifest.
REPO_BIN="$HOME/.local/bin/repo"
if ! command_exists repo; then
    log_info "Installing repo (Google)"
    mkdir -p "$HOME/.local/bin"
    curl -fsSL https://storage.googleapis.com/git-repo-downloads/repo -o "$REPO_BIN"
    chmod +x "$REPO_BIN"
fi

# ─── kas — modern Yocto-specific alternative ─────────────────────────────
# Pros over repo: YAML config, manages bblayers.conf and local.conf,
# reproducible build with `kas build`. https://kas.readthedocs.io
if command_exists pipx; then
    if ! pipx list 2>/dev/null | grep -q "package kas"; then
        log_info "Installing kas (via pipx)"
        pipx install kas
    fi
else
    log_warn "pipx missing — kas installable after 05-python."
fi

log_info "Quick workflow:"
log_info "  - XML manifest : repo init -u <URL> -b <branch> && repo sync"
log_info "  - YAML kas     : kas build kas-project.yml"
log_info "  - See topics/07-yocto/README.md for best practices."

log_success "07-yocto: OK"
