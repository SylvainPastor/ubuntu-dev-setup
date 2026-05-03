#!/usr/bin/env bash
# topics/03-cpp/profiling.sh: C/C++ profiling and analysis tools.
#
# perf is installed by 04-embedded/kernel.sh (linux-tools-generic).
# valgrind, lcov, gcovr, cppcheck are in 03-cpp/install.sh.
# Sanitizers (ASan, UBSan, TSan, MSan) are native to gcc/clang:
#   -fsanitize=address    -fsanitize=undefined
#   -fsanitize=thread     -fsanitize=memory  (clang only)

set -euo pipefail
# shellcheck source=SCRIPTDIR/../../lib/utils.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/utils.sh"

# ─── Memory and CPU profilers ────────────────────────────────────────────
apt_install \
    heaptrack \
    heaptrack-gui \
    hotspot \
    google-perftools \
    libgoogle-perftools-dev \
    massif-visualizer

# heaptrack         : memory profiler — much faster than valgrind/massif
# heaptrack-gui     : Qt visualization for heaptrack profiles
# hotspot           : Qt GUI for visualizing `perf record` profiles
# google-perftools  : tcmalloc + pprof (lightweight CPU/heap profiling, prod)
# massif-visualizer : GUI for visualizing massif profiles (valgrind --tool=massif)

# ─── CLI benchmarking ────────────────────────────────────────────────────
apt_install hyperfine
# hyperfine: reproducible benchmarks with stats and comparisons.
# Ex: hyperfine --warmup 3 './build/release/app' './build/debug/app'

# ─── Static security analysis ────────────────────────────────────────────
apt_install \
    flawfinder \
    iwyu

# flawfinder : detects dangerous patterns (strcpy, gets, format strings…)
# iwyu       : "Include What You Use" — optimizes #include directives
#              (faster builds, less header coupling)

cat <<'EOF'

  Useful workflows:

    # Memory profiling (heaptrack)
    heaptrack ./my_binary
    heaptrack_gui heaptrack.my_binary.NNNN.zst

    # CPU profiling (perf + hotspot)
    perf record --call-graph dwarf ./my_binary
    hotspot perf.data

    # Sanitizers (gcc/clang, no install needed)
    g++ -O1 -g -fsanitize=address,undefined -fno-omit-frame-pointer ...
    g++ -O1 -g -fsanitize=thread ...                      # data races

    # tcmalloc (gperftools) with heap profiler
    LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libtcmalloc.so.4 \
        HEAPPROFILE=/tmp/heap ./my_binary
    pprof --pdf ./my_binary /tmp/heap.0001.heap > heap.pdf

    # Comparative benchmarks
    hyperfine --warmup 3 './app_v1' './app_v2'

    # Static analysis
    flawfinder src/
    include-what-you-use -Xiwyu --error main.cpp 2>&1 | fix_include

EOF

log_success "Profiling: OK"
