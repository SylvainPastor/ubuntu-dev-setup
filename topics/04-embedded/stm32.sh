#!/usr/bin/env bash
# topics/04-embedded/stm32.sh: STM32 tools (open-source + ST installer detection).
#
# Open-source stack (auto)        : arm-none-eabi-gcc, openocd, stlink-tools,
#                                   stm32flash, gdb-multiarch (already installed).
# ST proprietary stack (manual)   : STM32CubeIDE, STM32CubeMX, STM32CubeProgrammer.
#                                   Requires an st.com account and license
#                                   acceptance — see README.md in this topic.

set -euo pipefail
# shellcheck source=SCRIPTDIR/../../lib/utils.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/utils.sh"

# ─── Open-source tools ───────────────────────────────────────────────────
apt_install \
    stm32flash \
    libusb-1.0-0-dev \
    libftdi1-dev

# ─── Auto-detection of ST installers in ~/Downloads ──────────────────────
# If you've downloaded the installer from st.com, we detect it and run
# the install. Otherwise we print a message with the procedure.
DOWNLOADS="${HOME}/Downloads"

# --- STM32CubeIDE -------------------------------------------------------
# ST installer named: st-stm32cubeide_X.Y.Z_BUILD_amd64_dpkg.sh (Ubuntu)
cubeide_already_installed() {
    compgen -G "/opt/st/stm32cubeide*" >/dev/null 2>&1
}

if ! cubeide_already_installed; then
    cubeide_installer=""
    if [[ -d "$DOWNLOADS" ]]; then
        cubeide_installer=$(find "$DOWNLOADS" -maxdepth 2 \
            -name 'st-stm32cubeide_*.sh' 2>/dev/null | sort -V | tail -1)
    fi
    if [[ -n "$cubeide_installer" ]]; then
        log_info "STM32CubeIDE: installer found → $cubeide_installer"
        log_warn "Interactive launch (license acceptance required)…"
        chmod +x "$cubeide_installer"
        sudo "$cubeide_installer" || log_warn "STM32CubeIDE install interrupted."
    else
        log_info "STM32CubeIDE: not installed. See topics/04-embedded/README.md"
    fi
fi

# --- STM32CubeProgrammer ------------------------------------------------
# Distributed as a .zip containing a Java installer SetupSTM32CubeProgrammer-*.linux
cubeprog_already_installed() {
    compgen -G "/opt/st/stm32cubeprogrammer*" >/dev/null 2>&1 \
        || command_exists STM32_Programmer_CLI
}

if ! cubeprog_already_installed; then
    cubeprog_zip=""
    if [[ -d "$DOWNLOADS" ]]; then
        cubeprog_zip=$(find "$DOWNLOADS" -maxdepth 2 \
            -iname 'en.stm32cubeprg*.zip' 2>/dev/null | sort -V | tail -1)
    fi
    if [[ -n "$cubeprog_zip" ]]; then
        log_info "STM32CubeProgrammer: archive found → $cubeprog_zip"
        # Java required for the graphical installer
        apt_install default-jre
        tmp=$(mktemp -d)
        unzip -q "$cubeprog_zip" -d "$tmp"
        installer=$(find "$tmp" -name 'SetupSTM32CubeProgrammer-*.linux' | head -1)
        if [[ -n "$installer" ]]; then
            chmod +x "$installer"
            log_warn "Interactive launch (license acceptance required)…"
            "$installer" || log_warn "STM32CubeProgrammer install interrupted."
        else
            log_warn "Installer not found in the archive."
        fi
        rm -rf "$tmp"
    else
        log_info "STM32CubeProgrammer: not installed. See topics/04-embedded/README.md"
    fi
fi

# ─── Reminder: useful VSCode extensions for STM32 ───────────────────────
# (Not auto-installed — IDs may evolve. Install manually or add to
#  02-dev-tools/install.sh once IDs are verified.)
log_info "Recommended VSCode extensions (install from marketplace):"
log_info "  - STMicroelectronics.stm32-vscode-extension  (official ST)"
log_info "  - marus25.cortex-debug                       (ARM Cortex-M debug)"
log_info "  - ms-vscode.cpptools                         (C/C++ IntelliSense)"

log_success "STM32: OK"
