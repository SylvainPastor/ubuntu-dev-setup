#!/usr/bin/env bash
# topics/03-cpp/install.sh: C/C++ toolchains and tools.

set -euo pipefail
# shellcheck source=SCRIPTDIR/../../lib/utils.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/utils.sh"

apt_install \
    gcc \
    g++ \
    gcc-multilib \
    g++-multilib \
    clang \
    lld \
    lldb \
    mold \
    clangd \
    clang-format \
    clang-tidy \
    clang-tools \
    cmake \
    cmake-curses-gui \
    ninja-build \
    meson \
    autoconf \
    automake \
    libtool \
    gdb \
    gdb-multiarch \
    valgrind \
    cppcheck \
    lcov \
    gcovr \
    doxygen \
    graphviz \
    libssl-dev \
    libcurl4-openssl-dev \
    libsystemd-dev \
    libbsd-dev \
    zlib1g-dev

# mold              : ultra-fast linker (10-20x faster than ld)
#                     Enable via: -fuse-ld=mold (clang) or
#                     CMAKE_LINKER_TYPE=MOLD (CMake 3.29+).
# gcc/g++-multilib  : compile 32-bit on a 64-bit host (embedded use case)
# libsystemd-dev    : systemd services, journald, sd-bus
# libbsd-dev        : strlcpy/strlcat and other BSD-isms

# Conan (C/C++ package manager) — installed via pipx.
# pipx is set up by 05-python; we tolerate its absence here.
if command_exists pipx; then
    if ! pipx list 2>/dev/null | grep -q "package conan"; then
        log_info "Installing Conan"
        pipx install conan
    fi
else
    log_warn "pipx missing: Conan will be installed after 05-python."
fi

# ─── Qt5 + Qt6 (sub-script) ──────────────────────────────────────────────
log_info "── Qt5 + Qt6 ──"
bash "$(dirname "${BASH_SOURCE[0]}")/qt.sh"

# ─── Profiling and analysis (sub-script) ─────────────────────────────────
log_info "── Profiling and analysis ──"
bash "$(dirname "${BASH_SOURCE[0]}")/profiling.sh"

log_success "03-cpp: OK"
