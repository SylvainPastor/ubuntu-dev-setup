#!/usr/bin/env bash
# topics/02-dev-tools/ide.sh: IDE / code editor installation.
#
# Currently covers:
#   - VSCode (Microsoft's official repository)
#   - Sublime Text (official repository)
#
# Other IDEs are installed by their respective topics:
#   - Qt Creator      => 03-cpp/qt.sh
#   - STM32CubeIDE    => 04-embedded/stm32.sh (manual download from st.com)

set -euo pipefail
# shellcheck source=SCRIPTDIR/../../lib/utils.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/utils.sh"

# ─── VSCode (Microsoft's official repository) ────────────────────────────
if ! command_exists code; then
    log_info "Installing VSCode"
    sudo install -m 0755 -d /etc/apt/keyrings
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc \
        | gpg --dearmor \
        | sudo tee /etc/apt/keyrings/packages.microsoft.gpg >/dev/null
    sudo chmod a+r /etc/apt/keyrings/packages.microsoft.gpg
    echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
        | sudo tee /etc/apt/sources.list.d/vscode.list >/dev/null
    sudo apt-get update -qq
    apt_install code
fi

# ─── Sublime Text (official repository) ──────────────────────────────────
# Reference: https://www.sublimetext.com/docs/linux_repositories.html
if ! command_exists subl; then
    log_info "Installing Sublime Text"
    sudo install -m 0755 -d /etc/apt/keyrings
    wget -qO- https://download.sublimetext.com/sublimehq-pub.gpg \
        | gpg --dearmor \
        | sudo tee /etc/apt/keyrings/sublimehq-archive.gpg >/dev/null
    sudo chmod a+r /etc/apt/keyrings/sublimehq-archive.gpg
    # The "stable" channel ships final releases; "dev" ships beta builds.
    echo "deb [signed-by=/etc/apt/keyrings/sublimehq-archive.gpg] https://download.sublimetext.com/ apt/stable/" \
        | sudo tee /etc/apt/sources.list.d/sublime-text.list >/dev/null
    sudo apt-get update -qq
    apt_install sublime-text
fi

log_success "IDE: OK"
