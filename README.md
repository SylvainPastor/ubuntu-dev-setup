# ubuntu-dev-setup

Automated provisioning of an **Ubuntu 24.04** workstation for **C / C++ / Python** development (with embedded focus).

Inspired by [`holman/dotfiles`](https://github.com/holman/dotfiles), each topic is isolated in its own folder under `topics/` and exposes a self-contained `install.sh`.

## Structure

```
.
├── bootstrap.sh            # Entry point
├── lib/
│   └── utils.sh            # Helpers (logs, idempotent apt, backup…)
└── topics/
    ├── 00-system/          # Base packages, build-essential, CLI utilities
    ├── 01-shell/           # zsh, oh-my-zsh, plugins, starship
    ├── 02-dev-tools/       # recent git (PPA), neovim, tmux, vscode, direnv
    ├── 03-cpp/             # gcc, clang, cmake, ninja, gdb, valgrind, cppcheck, conan
    ├── 04-embedded/        # arm-none-eabi, openocd, stlink, minicom, can-utils, udev
    ├── 05-python/          # mise, uv, pipx, ruff, black, mypy, poetry
    ├── 06-containers/      # docker (official repo), distrobox
    ├── 07-yocto/           # Yocto host deps, repo, kas, qemu, bmaptool, ccache
    └── 08-ros2/            # locale, ros-dev-tools, rosdep, colcon-mixin, ccache
```

The **numeric prefix** enforces execution order (system before the rest, Python before tools that depend on it, etc.).

## Usage

```bash
git clone https://github.com/SylvainPastor/ubuntu-dev-setup.git ~/dev-setup
cd ~/dev-setup
chmod +x bootstrap.sh

# Install everything
./bootstrap.sh

# Target one or more topics
./bootstrap.sh 03-cpp 04-embedded

# List available topics
./bootstrap.sh --list
```

## Testing the installation in a Docker container

To validate the scripts on a clean Ubuntu 24.04 without touching your workstation, a `Dockerfile` and `Makefile` are provided:

```bash
make                          # show targets
make build                    # build the Docker image
make test                     # run full bootstrap.sh in a fresh container
make test-topic TOPIC=03-cpp  # test a single topic
make shell                    # open a shell in the container (debug)
make test-idempotent          # run bootstrap.sh twice (idempotency check)
make clean                    # remove the image
```

The container starts from a minimal `ubuntu:24.04` image (just `sudo`, `ca-certificates`, `locales`), everything else must be installed by the scripts themselves, otherwise we'd hide bugs. 

Docker layer caching = fast iteration after the initial build.

## Principles

- **Idempotent**: every script can be re-run without breaking the system. `apt_install` only installs what's missing, git clones are conditional, etc.
- **Modular**: adding a topic = create `topics/NN-my-topic/install.sh`. Nothing else.
- **No magic**: everything is readable bash. You can run a topic by hand to see what it does.
- **No silent overwrites**: `backup_file()` is available in `utils.sh` for sensitive configs.

## Adding a topic

```bash
mkdir -p topics/09-my-topic
cat > topics/09-my-topic/install.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/utils.sh"

apt_install my-package

log_success "09-my-topic: OK"
EOF
chmod +x topics/09-my-topic/install.sh
```
