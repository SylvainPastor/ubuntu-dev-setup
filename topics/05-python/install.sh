#!/usr/bin/env bash
# topics/05-python/install.sh: Python: mise, uv, pipx, ruff, poetry, etc.

set -euo pipefail
# shellcheck source=SCRIPTDIR/../../lib/utils.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/utils.sh"

apt_install \
    python3 \
    python3-dev \
    python3-venv \
    python3-pip \
    pipx

# pipx adds ~/.local/bin to PATH
pipx ensurepath >/dev/null 2>&1 || true
export PATH="$HOME/.local/bin:$PATH"

# uv: ultra-fast Python package installer/manager (Astral)
if ! command_exists uv; then
    log_info "Installing uv"
    curl -LsSf https://astral.sh/uv/install.sh | sh
fi

# mise: multi-version manager (Python, Node, Go, etc.)
if ! command_exists mise; then
    log_info "Installing mise"
    curl -fsSL https://mise.run | sh
fi

# Global Python tools, isolated via pipx
for tool in ruff black mypy poetry pre-commit ipython; do
    if ! pipx list 2>/dev/null | grep -q "package $tool"; then
        log_info "pipx install $tool"
        pipx install "$tool"
    fi
done

log_success "05-python: OK"
