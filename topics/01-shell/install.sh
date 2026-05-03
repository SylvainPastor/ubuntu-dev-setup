#!/usr/bin/env bash
# topics/01-shell/install.sh: zsh, Oh My Zsh, plugins, Starship.

set -euo pipefail
# shellcheck source=SCRIPTDIR/../../lib/utils.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/utils.sh"

apt_install zsh

# Oh My Zsh (non-interactive mode)
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    log_info "Installing Oh My Zsh"
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# Common plugins
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
declare -A plugins=(
    [zsh-autosuggestions]="https://github.com/zsh-users/zsh-autosuggestions"
    [zsh-syntax-highlighting]="https://github.com/zsh-users/zsh-syntax-highlighting"
)
for name in "${!plugins[@]}"; do
    dest="$ZSH_CUSTOM/plugins/$name"
    if [[ ! -d "$dest" ]]; then
        log_info "zsh plugin: $name"
        git clone --depth=1 "${plugins[$name]}" "$dest"
    fi
done

# Starship — lightweight, configurable prompt
if ! command_exists starship; then
    log_info "Installing Starship"
    curl -fsSL https://starship.rs/install.sh | sh -s -- -y
fi

# zsh as default shell
if [[ "$(getent passwd "$USER" | cut -d: -f7)" != "$(command -v zsh)" ]]; then
    log_info "Setting zsh as default shell"
    chsh -s "$(command -v zsh)" || log_warn "chsh failed — set manually."
fi

log_success "01-shell: OK"
