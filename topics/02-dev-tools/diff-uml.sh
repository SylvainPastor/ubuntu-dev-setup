#!/usr/bin/env bash
# topics/02-dev-tools/diff-uml.sh: Diff/merge tools and UML modeling.

set -euo pipefail
# shellcheck source=SCRIPTDIR/../../lib/utils.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/utils.sh"

# ─── Diff / merge tools ──────────────────────────────────────────────────
# meld is installed by 02-dev-tools/install.sh.
apt_install \
    kdiff3 \
    diffuse \
    colordiff \
    icdiff

# meld      : 3-way merge GTK, the most popular (already installed)
# kdiff3    : 3-way merge Qt, sometimes preferred for complex conflicts
# diffuse   : lightweight GTK alternative
# colordiff : colorized `diff` for the terminal
# icdiff    : side-by-side diff in the terminal (more readable than diff -y)

# ─── UML / diagramming tools ─────────────────────────────────────────────
apt_install \
    umbrello \
    dia \
    plantuml

# umbrello : KDE UML modeler, supports all standard UML diagrams
#            (class, sequence, activity, state, components, deployment)
# dia      : general-purpose diagram editor (UML, ER, network, flowchart)
# plantuml : text-based diagrams (git-versionable)

# ─── drawio-desktop (GitHub release, not in Ubuntu) ──────────────────────
# drawio is the de-facto standard for collaborative diagramming today
# (free Lucidchart equivalent). The desktop version works offline.
if ! command_exists drawio; then
    log_info "Installing drawio-desktop"
    DRAWIO_VERSION=""
    if DRAWIO_VERSION=$(retry curl -fsSL \
        "https://api.github.com/repos/jgraph/drawio-desktop/releases/latest" \
        | grep -oP '"tag_name":\s*"v\K[^"]+' | head -1) && [[ -n "$DRAWIO_VERSION" ]]
    then
        ARCH="$(dpkg --print-architecture)"
        case "$ARCH" in
            amd64) DR_ARCH="amd64" ;;
            arm64) DR_ARCH="arm64" ;;
            *)     DR_ARCH=""      ;;
        esac
        if [[ -n "$DR_ARCH" ]]; then
            tmpdeb="$(mktemp --suffix=.deb)"
            url="https://github.com/jgraph/drawio-desktop/releases/download/v${DRAWIO_VERSION}/drawio-${DR_ARCH}-${DRAWIO_VERSION}.deb"
            if retry curl -fsSL -o "$tmpdeb" "$url"; then
                sudo apt-get install -y "$tmpdeb" || sudo apt-get install -fy
            else
                log_warn "drawio download failed — install manually."
            fi
            rm -f "$tmpdeb"
        else
            log_warn "Architecture $ARCH not supported by drawio binary."
        fi
    else
        log_warn "Could not fetch drawio version (GitHub rate-limit?)"
    fi
fi

cat <<'EOF'

  Diff/merge tools:
    meld a.txt b.txt              # GTK, most popular
    kdiff3 a.txt b.txt c.txt      # 3-way merge (conflict resolution)
    icdiff a.txt b.txt            # side-by-side diff in terminal
    git config --global merge.tool meld     # or kdiff3, diffuse…

  UML tools:
    umbrello                      # full GUI for all UML diagrams
    dia                           # general-purpose GUI (UML, network, ER…)
    drawio                        # de-facto standard, .drawio format
    plantuml diagram.puml         # text-based diagrams → SVG/PNG (git-versionable)

EOF

log_success "diff + UML: OK"
