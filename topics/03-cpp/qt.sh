#!/usr/bin/env bash
# topics/03-cpp/qt.sh: Qt5 and Qt6 (libs + tools + Qt Creator).
#
# Ubuntu 24.04 ships Qt 5.15.x (LTS) and Qt 6.4.x.
# For more recent versions (Qt 6.7+), use the qt.io online installer
# (Qt account required).

set -euo pipefail
# shellcheck source=SCRIPTDIR/../../lib/utils.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/utils.sh"

# ─── Qt5 (5.15.x on Ubuntu 24.04) ────────────────────────────────────────
# Qt5 is still widely used: many existing projects, active commercial
# LTS support until 2025+.
apt_install \
    qtbase5-dev \
    qtbase5-dev-tools \
    qtchooser \
    qt5-qmake \
    qttools5-dev \
    qttools5-dev-tools \
    qtdeclarative5-dev \
    qtmultimedia5-dev \
    libqt5svg5-dev \
    libqt5serialport5-dev \
    libqt5opengl5-dev \
    libqt5x11extras5-dev

# ─── Qt6 (6.4.x on Ubuntu 24.04) ─────────────────────────────────────────
# Qt6 is the modern branch, recommended for new projects.
apt_install \
    qt6-base-dev \
    qt6-base-dev-tools \
    qmake6 \
    qt6-tools-dev \
    qt6-tools-dev-tools \
    qt6-declarative-dev \
    qt6-multimedia-dev \
    qt6-svg-dev \
    qt6-serialport-dev \
    qt6-l10n-tools

# ─── Optional modules (uncomment as needed) ──────────────────────────────
# Qt5:
# apt_install qtwebengine5-dev qtcharts5-dev qt3d5-dev qtwayland5 \
#     libqt5sql5-mysql libqt5sql5-psql libqt5sql5-sqlite \
#     qtconnectivity5-dev qtpositioning5-dev qtsensors5-dev
#
# Qt6:
# apt_install qt6-webengine-dev qt6-charts-dev qt6-3d-dev qt6-wayland \
#     qt6-websockets-dev qt6-positioning-dev qt6-webchannel-dev \
#     qt6-connectivity-dev qt6-sensors-dev

# ─── Qt Creator (IDE, supports Qt5 and Qt6 simultaneously) ───────────────
apt_install qtcreator

# ─── System dependencies (X11, fonts, GL) ────────────────────────────────
# Required to compile and run Qt apps with graphical rendering.
apt_install \
    libgl1-mesa-dev \
    libxkbcommon-dev \
    libfontconfig1-dev

cat <<'EOF'

  Installed versions:
    qmake -query QT_VERSION     # Qt5 version (via qtchooser)
    qmake6 -query QT_VERSION    # Qt6 version

  Selecting Qt5 vs Qt6 (qtchooser):
    QT_SELECT=qt5 qmake -v
    QT_SELECT=qt6 qmake -v      # or directly qmake6

  CMake build (recommended for new projects):
    find_package(Qt6 REQUIRED COMPONENTS Core Widgets)
    target_link_libraries(myapp PRIVATE Qt6::Core Qt6::Widgets)

  qmake build (legacy):
    qmake6 -project && qmake6 && make

EOF

log_success "Qt5 + Qt6: OK"
