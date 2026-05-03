#!/usr/bin/env bash
# topics/04-embedded/kernel.sh: Linux kernel development.
#
# Covers:
#   - Official kernel build deps (Documentation/process/changes.rst)
#   - Linux cross toolchains (ARM64, ARM32) — distinct from arm-none-eabi
#     which is BARE-METAL and CANNOT compile a Linux kernel.
#   - Tracing / debug / static analysis tools
#   - LKML patch workflow (git-email, b4, quilt)
#   - virtme-ng to boot a VM directly from a kernel build

set -euo pipefail
# shellcheck source=SCRIPTDIR/../../lib/utils.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/utils.sh"

# ─── Linux kernel build dependencies ─────────────────────────────────────
# Reference: Documentation/process/changes.rst in the kernel sources.
apt_install \
    bc \
    bison \
    flex \
    libssl-dev \
    libelf-dev \
    libncurses-dev \
    libudev-dev \
    libpci-dev \
    libiberty-dev \
    dwarves \
    kmod \
    cpio \
    rsync \
    pkg-config \
    liblz4-dev \
    libzstd-dev \
    zstd

# Note: for kernel gcc plugins (KASAN, structleak, etc.), install the
# matching gcc-${VERSION}-plugin-dev package for your system gcc. Ex:
#   sudo apt install gcc-13-plugin-dev    # Ubuntu 24.04 (gcc 13 default)

# ─── Linux cross toolchains (userspace + kernel) ─────────────────────────
# Distinct from arm-none-eabi (bare-metal) installed by install.sh.
apt_install \
    gcc-aarch64-linux-gnu \
    binutils-aarch64-linux-gnu \
    libc6-dev-arm64-cross \
    gcc-arm-linux-gnueabihf \
    binutils-arm-linux-gnueabihf \
    libc6-dev-armhf-cross

# ─── Tracing, debug, crash analysis ──────────────────────────────────────
apt_install \
    crash \
    kexec-tools \
    trace-cmd \
    kernelshark \
    bpftrace \
    linux-tools-common \
    linux-tools-generic \
    libbpf-dev \
    sparse \
    coccinelle

# ─── QEMU to boot the kernel (x86, ARM, ARM64) ───────────────────────────
# Probably already installed by 07-yocto, but needed standalone too.
apt_install \
    qemu-system-x86 \
    qemu-system-arm \
    qemu-system-aarch64 \
    qemu-utils

# ─── Filesystem / images ─────────────────────────────────────────────────
apt_install \
    mtd-utils \
    squashfs-tools \
    e2fsprogs \
    initramfs-tools

# ─── Kernel docs (make htmldocs) — optional ──────────────────────────────
# Uncomment if you build the docs locally.
# apt_install python3-sphinx python3-sphinx-rtd-theme graphviz texlive-xetex

# ─── LKML patch workflow ─────────────────────────────────────────────────
# git-email provides git send-email (sending patches to mailing lists).
# quilt   : managing patch series.
# b4      : modern tool to fetch/send patches via lore.kernel.org.
apt_install \
    git-email \
    quilt

if command_exists pipx; then
    if ! pipx list 2>/dev/null | grep -q "package b4"; then
        log_info "Installing b4 (LKML patch workflow)"
        pipx install b4
    fi
    # virtme-ng: boot a VM directly from a kernel build, with no
    # pre-built rootfs. Excellent for fast iteration.
    if ! pipx list 2>/dev/null | grep -q "package virtme-ng"; then
        log_info "Installing virtme-ng"
        pipx install virtme-ng
    fi
else
    log_warn "pipx missing — b4 and virtme-ng installable after 05-python."
fi

cat <<'EOF'

  Quick cross-compile:
    ARM64  :  make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- defconfig
              make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- -j$(nproc)
    ARM32  :  make ARCH=arm   CROSS_COMPILE=arm-linux-gnueabihf- defconfig
              make ARCH=arm   CROSS_COMPILE=arm-linux-gnueabihf- -j$(nproc)

  Quick VM boot from your build:
    vng -r .                          # virtme-ng, from the built kernel dir

  See topics/04-embedded/README.md for details (full workflows, KASAN,
  ftrace, perf, patch submission).
EOF

log_success "Kernel: OK"
