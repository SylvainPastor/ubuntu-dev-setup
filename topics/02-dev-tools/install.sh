#!/usr/bin/env bash
# topics/02-dev-tools/install.sh: General dev tools.

set -euo pipefail
# shellcheck source=SCRIPTDIR/../../lib/utils.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/utils.sh"

apt_install \
    git \
    git-lfs \
    git-extras \
    tig \
    tmux \
    xclip \
    wl-clipboard \
    neovim \
    direnv \
    shellcheck \
    make \
    meld

# git-extras : useful commands (git ignore, git changelog, git summary…)
# tig        : git TUI, minimalist alternative to lazygit

# QoL (quality-of-life) tools.
# All available in Ubuntu 24.04 Universe — see lazygit + yq below for
# the two exceptions (GitHub releases).
apt_install \
    git-delta \
    zoxide \
    eza \
    gh \
    pandoc

# git-delta : git pager with syntax highlighting
# zoxide    : smart `cd` that learns your frequent directories
# eza       : modern `ls` with colors and git status
# gh        : official GitHub CLI
# pandoc    : universal Markdown ↔ anything converter
# (fzf, bat, tldr are already installed by 00-system)
# (plantuml is installed by diff-uml.sh, sub-script of this topic)

# ─── lazygit (GitHub release, not in Ubuntu 24.04) ───────────────────────
if ! command_exists lazygit; then
    log_info "Installing lazygit"
    LAZYGIT_VERSION=""
    if LAZYGIT_VERSION=$(retry curl -fsSL \
        "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" \
        | grep -oP '"tag_name":\s*"v\K[^"]+' | head -1) && [[ -n "$LAZYGIT_VERSION" ]]
    then
        ARCH="$(dpkg --print-architecture)"
        case "$ARCH" in
            amd64) LG_ARCH="x86_64" ;;
            arm64) LG_ARCH="arm64"  ;;
            *)     LG_ARCH=""       ;;
        esac
        if [[ -n "$LG_ARCH" ]]; then
            tmpdir=$(mktemp -d)
            url="https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_${LG_ARCH}.tar.gz"
            if retry curl -fsSL -o "$tmpdir/lazygit.tar.gz" "$url"; then
                tar -xzf "$tmpdir/lazygit.tar.gz" -C "$tmpdir" lazygit
                sudo install -m 0755 "$tmpdir/lazygit" /usr/local/bin/lazygit
            else
                log_warn "lazygit download failed — install manually."
            fi
            rm -rf "$tmpdir"
        else
            log_warn "Architecture $ARCH not supported by lazygit binary."
        fi
    else
        log_warn "Could not fetch lazygit version (GitHub rate-limit?)"
    fi
fi

# ─── yq (mikefarah — different from Ubuntu's `yq` which is jaq-like) ────
# We install via the GitHub binary to get the real mikefarah/yq.
if ! command_exists yq; then
    log_info "Installing yq (mikefarah)"
    ARCH="$(dpkg --print-architecture)"
    case "$ARCH" in
        amd64) YQ_ARCH="amd64" ;;
        arm64) YQ_ARCH="arm64" ;;
        *)     YQ_ARCH=""      ;;
    esac
    if [[ -n "$YQ_ARCH" ]]; then
        url="https://github.com/mikefarah/yq/releases/latest/download/yq_linux_${YQ_ARCH}"
        if retry sudo curl -fsSL -o /usr/local/bin/yq "$url"; then
            sudo chmod +x /usr/local/bin/yq
        else
            log_warn "yq download failed — install manually."
        fi
    else
        log_warn "Architecture $ARCH not supported by yq binary."
    fi
fi

# ─── IDEs (sub-script) ───────────────────────────────────────────────────
log_info "── IDEs ──"
bash "$(dirname "${BASH_SOURCE[0]}")/ide.sh"

# ─── Diff/merge + UML tools (sub-script) ─────────────────────────────────
log_info "── Diff/merge + UML ──"
bash "$(dirname "${BASH_SOURCE[0]}")/diff-uml.sh"

log_success "02-dev-tools: OK"
