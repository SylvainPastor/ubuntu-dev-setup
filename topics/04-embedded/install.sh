#!/usr/bin/env bash
# topics/04-embedded/install.sh: Common embedded tools + platforms.
#
# Common tools: ARM toolchain, JTAG/SWD probes, serial, CAN.
# Platforms   : sourced from arduino.sh, stm32.sh and kernel.sh.

set -euo pipefail
TOPIC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=SCRIPTDIR/../../lib/utils.sh
source "${TOPIC_DIR}/../../lib/utils.sh"

# ─── ARM toolchain and common tools ──────────────────────────────────────
apt_install \
    gcc-arm-none-eabi \
    binutils-arm-none-eabi \
    libnewlib-arm-none-eabi \
    libnewlib-dev \
    gdb-multiarch \
    openocd \
    stlink-tools \
    dfu-util \
    srecord \
    minicom \
    picocom \
    screen \
    can-utils \
    socat \
    python3-serial

# ─── Wireshark + tshark ──────────────────────────────────────────────────
# Essential whenever you deal with Ethernet / CAN over IP / Modbus TCP.
# The wireshark-common package asks a debconf question — we pre-answer
# it so the install stays non-interactive and authorizes capture by
# non-root users via setcap (the `wireshark` group).
echo "wireshark-common wireshark-common/install-setuid boolean true" \
    | sudo debconf-set-selections
apt_install wireshark tshark

# Add to wireshark group (capture without sudo)
if getent group wireshark >/dev/null 2>&1 && ! id -nG "$USER" | grep -qw wireshark; then
    log_info "Adding $USER to wireshark group"
    sudo usermod -aG wireshark "$USER"
    log_warn "Re-login required to activate wireshark group."
fi

# ─── Serial/USB permissions ──────────────────────────────────────────────
for grp in dialout plugdev; do
    if ! id -nG "$USER" | grep -qw "$grp"; then
        log_info "Adding $USER to $grp group"
        sudo usermod -aG "$grp" "$USER"
        log_warn "Re-login required to activate $grp group."
    fi
done

# ─── ST-Link v2 udev rules ───────────────────────────────────────────────
UDEV_RULES_DIR=/etc/udev/rules.d
if [[ ! -f "$UDEV_RULES_DIR/49-stlinkv2.rules" ]]; then
    log_info "Installing ST-Link udev rules"
    if sudo curl -fsSL -o "$UDEV_RULES_DIR/49-stlinkv2.rules" \
        https://raw.githubusercontent.com/stlink-org/stlink/master/config/udev/rules.d/49-stlinkv2.rules
    then
        sudo udevadm control --reload-rules
        sudo udevadm trigger
    else
        log_warn "ST-Link udev rules download failed — install manually."
    fi
fi

# ─── Additional embedded tools ───────────────────────────────────────────
apt_install \
    i2c-tools \
    flashrom \
    bluez-tools

# i2c-tools   : i2cdetect, i2cdump, i2cset (I2C sensors from the host)
# flashrom    : direct SPI-NOR flashing (BIOS, U-Boot…) via USB programmer
# bluez-tools : BLE testing (bluetoothctl, gatttool, hcitool)

# I2C/SPI bus access without sudo
if getent group i2c >/dev/null 2>&1 && ! id -nG "$USER" | grep -qw i2c; then
    log_info "Adding $USER to i2c group"
    sudo usermod -aG i2c "$USER"
    log_warn "Re-login required to activate i2c group."
fi

# ─── NFS server + TFTP server (embedded kernel workflow) ─────────────────
# Classic pattern: the target boots via TFTP (uImage + dtb) and mounts
# its rootfs over NFS from your workstation. Avoids flashing 50× a day.
#
# Services are installed but disabled at boot by default (security: no
# network listening until you actually need it). Enable them when working
# on a target:
#   sudo systemctl start nfs-kernel-server tftpd-hpa
#   # and configure /etc/exports + /srv/tftp for your workflow
apt_install \
    nfs-kernel-server \
    tftpd-hpa

# Disable at boot (skipped in Docker — systemctl unavailable)
if command_exists systemctl && [[ -d /run/systemd/system ]]; then
    for svc in nfs-kernel-server tftpd-hpa; do
        if systemctl is-enabled "$svc" >/dev/null 2>&1; then
            log_info "Disabling $svc at boot (security)"
            sudo systemctl disable "$svc" >/dev/null 2>&1 || true
            sudo systemctl stop "$svc" >/dev/null 2>&1 || true
        fi
    done
fi

# ─── Platforms ───────────────────────────────────────────────────────────
log_info "── Platform: Arduino ──"
bash "${TOPIC_DIR}/arduino.sh"

log_info "── Platform: STM32 ──"
bash "${TOPIC_DIR}/stm32.sh"

log_info "── Platform: Linux Kernel ──"
bash "${TOPIC_DIR}/kernel.sh"

log_success "04-embedded: OK"
