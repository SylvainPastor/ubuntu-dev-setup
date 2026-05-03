# Topic 08-ros2

Host setup to **build ROS 2 from sources** on Ubuntu 24.04.

Based on the official procedure:
https://docs.ros.org/en/rolling/Installation/Alternatives/Ubuntu-Development-Setup.html

## Automated coverage

| Step                           | Result                                                         |
|--------------------------------|----------------------------------------------------------------|
| Locale                         | `en_US.UTF-8` generated and active                             |
| Ubuntu Universe repo           | Enabled                                                        |
| ROS 2 apt repo                 | Managed via the official `ros2-apt-source` package             |
| Dev tools                      | `ros-dev-tools` (colcon, vcstool, rosdep, …) + pytest plugins  |
| colcon extensions              | `colcon-mixin`, `colcon-clean`                                 |
| Performance                    | `ccache` (used via `--mixin ccache`)                           |
| `rosdep`                       | `init` (root) + `update` (user) — idempotent                   |
| colcon mixins                  | Official repo added (`release`, `debug`, `ccache`, `asan`…)    |

This topic prepares the host **only**; it does not clone sources nor run `colcon`. The build workflow is below.

## Standard workflow (Rolling from sources)

```bash
# 1. Workspace
mkdir -p ~/ros2_rolling/src && cd ~/ros2_rolling

# 2. Import repositories via vcstool
vcs import --input https://raw.githubusercontent.com/ros2/ros2/rolling/ros2.repos src

# 3. Update the system before rosdep
sudo apt update && sudo apt upgrade

# 4. Install system dependencies
rosdep install --from-paths src --ignore-src -y \
    --skip-keys "fastcdr rti-connext-dds-7.7.0 urdfdom_headers"

# 5. Build (release + ccache)
colcon build --symlink-install --mixin release ccache

# 6. Source the workspace
. ~/ros2_rolling/install/local_setup.bash

# 7. Test
ros2 run demo_nodes_cpp talker
ros2 run demo_nodes_py listener
```

For **Jazzy** or **Humble**, change the `vcs import` URL:
```bash
vcs import --input https://raw.githubusercontent.com/ros2/ros2/jazzy/ros2.repos src
```

## Updating an existing checkout

```bash
cd ~/ros2_rolling
vcs pull src             # update all repositories
rosdep install --from-paths src --ignore-src -y --skip-keys "..."
colcon build --symlink-install --mixin release ccache
```

Docs: https://docs.ros.org/en/rolling/Installation/Maintaining-a-Source-Checkout.html

## Useful colcon mixins

Once `colcon-mixin` is configured, these profiles are available:

```bash
colcon build --mixin release           # CMAKE_BUILD_TYPE=Release
colcon build --mixin debug             # CMAKE_BUILD_TYPE=Debug
colcon build --mixin ccache            # enables ccache via CMAKE_*_COMPILER_LAUNCHER
colcon build --mixin asan-gcc          # AddressSanitizer
colcon build --mixin compile-commands  # generate compile_commands.json (clangd)
# Combinable:
colcon build --mixin release ccache compile-commands
```

Full list: `colcon mixin show`.

## Important best practices

### Never source two ROS 2 installs at the same time

```bash
# ❌ NEVER do this:
. /opt/ros/jazzy/setup.bash
. ~/ros2_rolling/install/local_setup.bash

# ❌ And do NOT put `source /opt/ros/...` in your .bashrc/.zshrc
#    if you also use a source build.
```

Check: `printenv | grep -i ROS` should be empty before sourcing a source workspace.

### No root for colcon nor rosdep update

- `sudo colcon build` → disaster (broken perms in `build/`, `install/`).
- `sudo rosdep update` → contaminates `/root/.ros/`. Always run as a regular user.
- `sudo rosdep init` → only for the **first** system init (already handled by the script).

### Disk space

A full Rolling build = **~25 GB** (`build/` + `install/` + `log/`) + `src/` (~2 GB). Plan for double to have margin with ccache.

### Colcon clean

```bash
colcon clean workspace            # clean build/ install/ log/
colcon clean packages --packages-select my_pkg
```

Much cleaner than `rm -rf build install log`.

## Coexistence of multiple distributions

To have Rolling, Jazzy and Humble in parallel, **one workspace per distro**:

```
~/ros2_rolling/   # Rolling checkout
~/ros2_jazzy/     # Jazzy checkout
~/ros2_humble/    # Humble checkout
```

Never source two of them in the same shell. Useful tricks in `~/.zshrc`:

```bash
ros2_rolling() { . ~/ros2_rolling/install/local_setup.bash; }
ros2_jazzy()   { . ~/ros2_jazzy/install/local_setup.bash;   }
ros2_humble()  { . ~/ros2_humble/install/local_setup.bash;  }
```

You only activate the distro when you're working on it.

## Alternative compiler (Clang)

`clang` is already installed by `03-cpp`. To use it:

```bash
export CC=clang
export CXX=clang++
colcon build --cmake-force-configure
```

## Alternative RMWs (Cyclone DDS, Zenoh…)

The default RMW is Fast DDS. To use Cyclone DDS:

```bash
# At build time (included in the source workspace)
# At runtime:
export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
```

Docs: https://docs.ros.org/en/rolling/Installation/RMW-Implementations.html

## Useful VSCode extensions

- **ROS** (Microsoft) — `ms-iot.vscode-ros`: package navigation, launch, debug
- **C/C++** — `ms-vscode.cpptools`
- **Python** — `ms-python.python`
- **CMake Tools** — `ms-vscode.cmake-tools`
- **XML** — `redhat.vscode-xml`: for `package.xml` and URDF
- **clangd** — `llvm-vs-code-extensions.vscode-clangd` (faster cpptools alternative)

To get the most out of `clangd`, build with `--mixin compile-commands` and create a symlink at the root:
```bash
ln -s build/compile_commands.json compile_commands.json
```

## Quick troubleshooting

| Symptom                                      | Hint                                                     |
|----------------------------------------------|----------------------------------------------------------|
| `Unsupported OS [mint]` on `rosdep install`  | Add `--os=ubuntu:noble`                                  |
| `command not found: ros2`                    | Source `install/local_setup.bash`                        |
| Build crashes on `image_tools`               | `--packages-skip image_tools intra_process_demo`         |
| `bind: Address already in use` on talker     | `ROS_DOMAIN_ID` conflict — pick an ID 0-101              |
| Slow incremental builds                      | Check `ccache -s`; enable the `ccache` mixin             |

Official troubleshooting docs: https://docs.ros.org/en/rolling/How-To-Guides/Installation-Troubleshooting.html
