#!/usr/bin/env bash
# bootstrap.sh — Entry point. Runs all topics or a subset.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
# shellcheck source=lib/utils.sh
source "${SCRIPT_DIR}/lib/utils.sh"

usage() {
    cat <<EOF
Usage: $(basename "$0") [TOPIC...]

Without arguments: runs all topics in alphabetical order.
Otherwise        : runs only the topics passed as arguments.

Available topics:
$(find "${SCRIPT_DIR}/topics" -mindepth 1 -maxdepth 1 -type d -printf '  %f\n' | sort)

Examples:
  $(basename "$0")                       # full installation
  $(basename "$0") 03-cpp 04-embedded    # only C/C++ and embedded
  $(basename "$0") --list                # list without running
EOF
}

case "${1:-}" in
    -h|--help)  usage; exit 0 ;;
    --list)
        find "${SCRIPT_DIR}/topics" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort
        exit 0 ;;
esac

ensure_ubuntu

# Ask for sudo once and keep it alive for the duration of the run.
# We use `sudo true` rather than `sudo -v`: the latter can prompt for a
# password even with NOPASSWD configured (e.g. in the test container).
log_info "Elevating privileges (sudo)…"
sudo true
( while true; do sudo -n true; sleep 60; kill -0 "$$" 2>/dev/null || exit; done ) &
readonly SUDO_KEEPALIVE_PID=$!
trap 'kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true' EXIT

apt_update_once

# Topic selection
if [[ $# -eq 0 ]]; then
    mapfile -t topics < <(find "${SCRIPT_DIR}/topics" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)
else
    topics=("$@")
fi

for topic in "${topics[@]}"; do
    script="${SCRIPT_DIR}/topics/${topic}/install.sh"
    if [[ ! -f "$script" ]]; then
        log_warn "Unknown topic, skipping: ${topic}"
        continue
    fi
    log_info "════════════ ${topic} ════════════"
    bash "$script"
done

log_success "Installation complete."
log_warn "Remember to log out and back in to apply group changes (docker, dialout, etc.)."
