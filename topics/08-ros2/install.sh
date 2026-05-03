#!/usr/bin/env bash
# topics/08-ros2/install.sh: Host setup to build ROS 2 from sources.
#
# Official reference:
# https://docs.ros.org/en/rolling/Installation/Alternatives/Ubuntu-Development-Setup.html
#
# This script does NOT clone sources and does NOT run colcon — it only
# prepares the host (locale, repos, tools, rosdep, ccache, mixins).
# The build workflow is documented in this topic's README.md.

set -euo pipefail
# shellcheck source=SCRIPTDIR/../../lib/utils.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/utils.sh"

# ─── 1. en_US.UTF-8 locale (required by ROS 2) ───────────────────────────
if ! locale -a 2>/dev/null | grep -qiE '^en_US\.utf-?8$'; then
    log_info "Generating en_US.UTF-8 locale"
    apt_install locales
    sudo locale-gen en_US en_US.UTF-8
    sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
fi

# ─── 2. Enable Ubuntu Universe repository ────────────────────────────────
apt_install software-properties-common
sudo add-apt-repository -y universe

# ─── 3. ROS 2 apt repository via ros2-apt-source ─────────────────────────
# The ros2-apt-source package handles the GPG keys and ROS 2 repo
# configuration with automatic updates.
if ! dpkg -s ros2-apt-source >/dev/null 2>&1; then
    log_info "Installing ros2-apt-source"
    apt_install curl ca-certificates

    ROS_APT_SOURCE_VERSION=$(
        curl -fsSL https://api.github.com/repos/ros-infrastructure/ros-apt-source/releases/latest \
            | grep -F '"tag_name"' | awk -F'"' '{print $4}'
    )
    if [[ -z "$ROS_APT_SOURCE_VERSION" ]]; then
        log_error "Could not fetch the latest ros-apt-source release (GitHub rate-limit?)"
        exit 1
    fi
    log_info "Latest ros-apt-source release: ${ROS_APT_SOURCE_VERSION}"

    UBUNTU_CN="$(. /etc/os-release && echo "${UBUNTU_CODENAME:-${VERSION_CODENAME}}")"
    DEB_URL="https://github.com/ros-infrastructure/ros-apt-source/releases/download/${ROS_APT_SOURCE_VERSION}/ros2-apt-source_${ROS_APT_SOURCE_VERSION}.${UBUNTU_CN}_all.deb"

    log_info "Downloading the .deb"
    curl -fsSL -o /tmp/ros2-apt-source.deb "$DEB_URL"
    sudo dpkg -i /tmp/ros2-apt-source.deb || sudo apt-get install -fy
    rm -f /tmp/ros2-apt-source.deb
    sudo apt-get update -qq
fi

# ─── 4. ROS 2 development tools ──────────────────────────────────────────
# ros-dev-tools = ROS 2 meta-package (colcon, vcstool, rosdep, etc.)
apt_install \
    python3-mypy \
    python3-pip \
    python3-pytest \
    python3-pytest-cov \
    python3-pytest-mock \
    python3-pytest-repeat \
    python3-pytest-rerunfailures \
    python3-pytest-runner \
    python3-pytest-timeout \
    ros-dev-tools

# ─── 5. Additional colcon extensions ─────────────────────────────────────
# colcon-mixin: pre-defined build profiles (release, debug, ccache, asan…)
# colcon-clean: selective cleanup (build/, install/, log/)
apt_install \
    python3-colcon-mixin \
    python3-colcon-clean

# ─── 6. ccache to speed up rebuilds ──────────────────────────────────────
# Enable via the "ccache" mixin: colcon build --mixin ccache
apt_install ccache

# ─── 7. Alternative compiler (Clang) — optional ──────────────────────────
# Uncomment if you want to be able to build ROS 2 with Clang (CC=clang
# CXX=clang++). Already installed by 03-cpp normally.
# apt_install clang lld

# ─── 8. rosdep init/update ───────────────────────────────────────────────
# `sudo rosdep init` runs only once per machine.
# `rosdep update` runs per user (never as sudo).
if [[ ! -f /etc/ros/rosdep/sources.list.d/20-default.list ]]; then
    log_info "sudo rosdep init"
    sudo rosdep init
fi
log_info "rosdep update (user)"
rosdep update || log_warn "rosdep update failed — retry manually."

# ─── 9. Default colcon mixins ────────────────────────────────────────────
if command_exists colcon; then
    if ! colcon mixin list 2>/dev/null | grep -q '^- default'; then
        log_info "Adding the default colcon mixin repository"
        colcon mixin add default \
            https://raw.githubusercontent.com/colcon/colcon-mixin-repository/master/index.yaml || true
        colcon mixin update default || true
    fi
fi

cat <<'EOF'

──────────────────────────────────────────────────────────────────────────
 Typical workflow to build ROS 2 Rolling from sources:

   mkdir -p ~/ros2_rolling/src && cd ~/ros2_rolling
   vcs import --input https://raw.githubusercontent.com/ros2/ros2/rolling/ros2.repos src
   sudo apt upgrade
   rosdep install --from-paths src --ignore-src -y \
       --skip-keys "fastcdr rti-connext-dds-7.7.0 urdfdom_headers"
   colcon build --symlink-install --mixin release ccache

   # Source after each build:
   . ~/ros2_rolling/install/local_setup.bash

 See topics/08-ros2/README.md for details and best practices.
──────────────────────────────────────────────────────────────────────────
EOF

log_success "08-ros2: OK"
