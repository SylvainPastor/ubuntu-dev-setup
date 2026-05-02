#!/usr/bin/env bash
# lib/utils.sh — Common helpers for topics.
# Source this file (do not execute directly).

# Ensures $USER is defined; it can be missing in minimalistic environments
# (Docker containers without a login shell).
export USER="${USER:-$(id -un)}"

# Colors
readonly C_RESET='\033[0m'
readonly C_RED='\033[0;31m'
readonly C_GREEN='\033[0;32m'
readonly C_YELLOW='\033[0;33m'
readonly C_BLUE='\033[0;34m'

log_info()    { printf "${C_BLUE}[INFO]${C_RESET}  %s\n" "$*"; }
log_warn()    { printf "${C_YELLOW}[WARN]${C_RESET}  %s\n" "$*"; }
log_error()   { printf "${C_RED}[ERROR]${C_RESET} %s\n" "$*" >&2; }
log_success() { printf "${C_GREEN}[ OK ]${C_RESET}  %s\n" "$*"; }

command_exists() { command -v "$1" >/dev/null 2>&1; }

# retry CMD ARGS  — retries up to 3 times with exponential backoff.
# Useful for flaky network calls (Launchpad, GitHub API, etc.).
retry() {
    local max_attempts=3
    local delay=2
    local attempt=1
    while (( attempt <= max_attempts )); do
        if "$@"; then
            return 0
        fi
        if (( attempt < max_attempts )); then
            log_warn "Failed (attempt ${attempt}/${max_attempts}), retrying in ${delay}s…"
            sleep "$delay"
            delay=$(( delay * 2 ))
        fi
        attempt=$(( attempt + 1 ))
    done
    return 1
}

# apt_install pkg1 pkg2 ...   — installs only what's missing
apt_install() {
    local packages=("$@")
    local to_install=()
    for pkg in "${packages[@]}"; do
        if ! dpkg -s "$pkg" >/dev/null 2>&1; then
            to_install+=("$pkg")
        fi
    done
    if [[ ${#to_install[@]} -gt 0 ]]; then
        log_info "apt install: ${to_install[*]}"
        sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "${to_install[@]}"
    fi
}

# Run apt-get update only once per day (avoids cascading runs)
apt_update_once() {
    local stamp
    stamp="/tmp/.apt-updated-$(date +%Y%m%d)"
    if [[ ! -f "$stamp" ]]; then
        log_info "apt-get update"
        sudo apt-get update -qq
        touch "$stamp"
    fi
}

# Verify we are running on Ubuntu
ensure_ubuntu() {
    if ! grep -qi "ubuntu" /etc/os-release 2>/dev/null; then
        log_error "This project targets Ubuntu only."
        exit 1
    fi
}

# Backup a file before overwriting it
backup_file() {
    local file="$1"
    if [[ -f "$file" && ! -L "$file" ]]; then
        local backup
        backup="${file}.backup-$(date +%Y%m%d-%H%M%S)"
        cp "$file" "$backup"
        log_info "Backup: $file -> $backup"
    fi
}
