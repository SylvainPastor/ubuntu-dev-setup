#!/usr/bin/env bash
# topics/04-embedded/arduino.sh: arduino-cli + cores + additional URLs.
#
# arduino-cli is the official command-line tool. It's a much better fit
# than the Arduino IDE for a scripted/CI workflow.
# Docs: https://arduino.github.io/arduino-cli/

set -euo pipefail
# shellcheck source=SCRIPTDIR/../../lib/utils.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/utils.sh"

# Local installation (no sudo needed)
ARDUINO_BIN_DIR="$HOME/.local/bin"
mkdir -p "$ARDUINO_BIN_DIR"
export PATH="$ARDUINO_BIN_DIR:$PATH"

if ! command_exists arduino-cli; then
    log_info "Installing arduino-cli to $ARDUINO_BIN_DIR"
    curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh \
        | BINDIR="$ARDUINO_BIN_DIR" sh
fi

# Initial configuration (~/.arduino15/arduino-cli.yaml)
if [[ ! -f "$HOME/.arduino15/arduino-cli.yaml" ]]; then
    log_info "Initializing arduino-cli"
    arduino-cli config init
fi

# Additional Boards Manager URLs — uncomment those you need.
declare -a additional_urls=(
    "https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json"
    "https://arduino.esp8266.com/stable/package_esp8266com_index.json"
    "https://github.com/stm32duino/BoardManagerFiles/raw/main/package_stmicroelectronics_index.json"
)
current_urls=$(arduino-cli config get board_manager.additional_urls 2>/dev/null || true)
for url in "${additional_urls[@]}"; do
    if ! echo "$current_urls" | grep -qF "$url"; then
        arduino-cli config add board_manager.additional_urls "$url"
        log_info "Added boards manager URL: $url"
    fi
done

arduino-cli core update-index

# Cores to install.
# By default we only install `arduino:avr` (Uno/Nano/Mega) to avoid
# downloading hundreds of MB. Uncomment based on your targets.
declare -a cores=(
    "arduino:avr"                          # Uno, Nano, Mega, Leonardo, Pro Mini
    # "arduino:samd"                       # Zero, MKR-series
    # "esp32:esp32"                        # ESP32 (all variants)
    # "esp8266:esp8266"                    # ESP8266 / NodeMCU
    "STMicroelectronics:stm32"             # STM32 via the stm32duino core
)
for core in "${cores[@]}"; do
    if ! arduino-cli core list 2>/dev/null | awk 'NR>1 {print $1}' | grep -qx "$core"; then
        log_info "Installing Arduino core: $core"
        arduino-cli core install "$core" || log_warn "Failed to install core $core"
    fi
done

# Common global libraries (optional) — uncomment as needed.
# declare -a libs=(
#     "Adafruit GFX Library"
#     "ArduinoJson"
#     "Wire"
# )
# for lib in "${libs[@]}"; do
#     arduino-cli lib install "$lib" 2>/dev/null || true
# done

log_info "List connected boards : arduino-cli board list"
log_info "Compile               : arduino-cli compile --fqbn arduino:avr:uno sketch/"
log_info "Upload                : arduino-cli upload  --fqbn arduino:avr:uno -p /dev/ttyACM0 sketch/"

log_success "Arduino: OK"
