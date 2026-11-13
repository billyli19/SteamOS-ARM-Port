#!/usr/bin/env bash
# extra-cmake-modules for KDE builds inside the Frame rootfs. Valve's SM8750
# rootfs has cmake and the KDE headers but not ECM; it comes from Arch Linux
# ARM (CMake scripts only, no binaries), the same source
# build-plasma-keyboard.sh uses.
#
# Usage: ensure-ecm-in-rootfs.sh <rootfs>
set -euo pipefail
R="$(cd "${1:?rootfs}" && pwd)"
[[ -f "$R/usr/share/ECM/cmake/ECMConfig.cmake" ]] && exit 0
REPO="${ECM_REPO:-http://mirror.archlinuxarm.org/aarch64/extra}"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
echo "==> installing extra-cmake-modules into rootfs"
curl -fsSL --retry 3 --max-time 120 -o "$tmp/extra.db" "$REPO/extra.db"
files="$(tar -xOf "$tmp/extra.db" --wildcards 'extra-cmake-modules-*/desc' \
  | sed -n '/^extra-cmake-modules-.*\.pkg\.tar/p')"
file="${files%%$'\n'*}"
[[ -n "$file" ]] || { echo "ERROR: extra-cmake-modules not in $REPO/extra.db" >&2; exit 1; }
curl -fsSL --retry 3 --max-time 120 -o "$tmp/$file" "$REPO/$file"
mkdir "$tmp/x"
tar -C "$tmp/x" -xf "$tmp/$file"
mkdir -p "$R/usr/share"
cp -a "$tmp/x/usr/share/ECM" "$R/usr/share/"
[[ -f "$R/usr/share/ECM/cmake/ECMConfig.cmake" ]] || { echo "ERROR: ECM still missing" >&2; exit 1; }
echo "==> extra-cmake-modules: $file"
