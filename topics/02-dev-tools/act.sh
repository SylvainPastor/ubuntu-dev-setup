#!/usr/bin/env bash
# topics/02-dev-tools/act.sh: Run your gitHub Actions locally.
# https://docs.github.com/en/actions

set -euo pipefail
# shellcheck source=SCRIPTDIR/../../lib/utils.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/utils.sh"

# ─── act (GitHub release, not in Ubuntu) ─────────────────────────────────
# act runs GitHub Actions workflows locally (fast CI debugging).
if ! command_exists act; then
    log_info "Installing act"
    ARCH="$(dpkg --print-architecture)"
    case "$ARCH" in
        amd64) ACT_ARCH="x86_64" ;;
        arm64) ACT_ARCH="arm64"  ;;
        *)     ACT_ARCH=""       ;;
    esac
    if [[ -n "$ACT_ARCH" ]]; then
        ACT_VERSION=""
        if ACT_VERSION=$(retry curl -fsSL \
            "https://api.github.com/repos/nektos/act/releases/latest" \
            | grep -oP '"tag_name":\s*"v\K[^"]+' | head -1) && [[ -n "$ACT_VERSION" ]]
        then
            tmpdir=$(mktemp -d)
            url="https://github.com/nektos/act/releases/download/v${ACT_VERSION}/act_Linux_${ACT_ARCH}.tar.gz"
            if retry curl -fsSL -o "$tmpdir/act.tar.gz" "$url"; then
                tar -xzf "$tmpdir/act.tar.gz" -C "$tmpdir" act
                sudo install -m 0755 "$tmpdir/act" /usr/local/bin/act
            else
                log_warn "act download failed — install manually."
            fi
            rm -rf "$tmpdir"
        else
            log_warn "Could not fetch act version (GitHub rate-limit?)"
        fi
    else
        log_warn "Architecture $ARCH not supported by act binary."
    fi
fi

log_success "act: OK"
