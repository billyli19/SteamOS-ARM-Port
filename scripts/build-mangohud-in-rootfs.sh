#!/usr/bin/env bash
# Build mangoapp (Steam's performance overlay) inside the SteamOS rootfs, so
# it links against SteamOS's glibc: MangoHud v0.8.4 + the patches in
# external-and-mods/MangoHud-qualcomm (GPU load, clock and VRAM on Adreno).
#
# Usage: build-mangohud-in-rootfs.sh <rootfs> [build-dir]
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
R="$(cd "${1:?rootfs}" && pwd)"
WORKDIR="${STEAMOS_WORK:-/work}"
BUILD="${2:-${WORKDIR}/mangohud-build}"
TAG=v0.8.4
log() { printf '==> [mangohud] %s\n' "$*"; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
command -v bwrap >/dev/null || die "bwrap required"
[[ -x "$R/usr/bin/gcc" && -x "$R/usr/bin/python3" ]] || die "rootfs needs gcc + python3"

T="$R/t/mangohud"                       # inside the rootfs: /t/mangohud
rm -rf "$T/src"; mkdir -p "$T"
log "MangoHud $TAG"
curl -fsSL "https://github.com/flightlessmango/MangoHud/archive/refs/tags/${TAG}.tar.gz" | tar -xz -C "$T"
mv "$T/MangoHud-${TAG#v}" "$T/src"
for p in "$ROOT/external-and-mods/MangoHud-qualcomm/patches/"*.patch; do
  log "patch $(basename "$p")"
  patch -d "$T/src" -p1 --quiet < "$p"
done
# v0.8.4 wants a newer meson than the rootfs has: a private copy for the build.
[[ -d "$T/pymeson/mesonbuild" ]] || python3 -m pip install -q --target "$T/pymeson" "meson==1.8.2"
# The bundled libraries (imgui, implot, spdlog, Vulkan headers) are fetched out
# here, where the network is known to work; the build inside then finds them.
PYTHONPATH="$T/pymeson" PYTHONDONTWRITEBYTECODE=1 python3 -m mesonbuild.mesonmain subprojects download \
  --sourcedir "$T/src" || log "WARN: could not pre-fetch every subproject, the build fetches the rest"
# DNS for whatever is still fetched inside: the host's resolv.conf, bound where
# the rootfs's /etc/resolv.conf points (a symlink into /run on SteamOS, which
# a plain bind onto /etc/resolv.conf cannot follow).
RESOLV_SRC="$(readlink -f /etc/resolv.conf)"
RESOLV=() MADE_RESOLV=0
if [[ -L "$R/etc/resolv.conf" ]]; then
  l="$(readlink "$R/etc/resolv.conf")"; [[ "$l" == /* ]] || l="/etc/$l"
  d="$(realpath -m -s "$l")"
  [[ "$d" == /run/* ]] && RESOLV+=(--tmpfs /run)
  RESOLV+=(--dir "$(dirname "$d")" --ro-bind "$RESOLV_SRC" "$d")
else
  [[ -e "$R/etc/resolv.conf" ]] || MADE_RESOLV=1
  RESOLV+=(--ro-bind "$RESOLV_SRC" /etc/resolv.conf)
fi
bwrap --bind "$R" / --dev /dev --proc /proc --tmpfs /tmp "${RESOLV[@]}" \
  bash -c 'set -e; export PYTHONPATH=/t/mangohud/pymeson PYTHONDONTWRITEBYTECODE=1
    cd /t/mangohud/src
    rm -rf /t/mangohud/build
    python3 -m mesonbuild.mesonmain setup /t/mangohud/build --buildtype=release --prefix=/usr \
      -Dmangoapp=true -Dmangohudctl=false -Dwith_xnvctrl=disabled -Dwith_nvml=disabled \
      -Dtests=disabled -Dinclude_doc=false -Dmangoplot=disabled >/dev/null
    ninja -C /t/mangohud/build src/mangoapp'
mkdir -p "$BUILD"
install -m0755 "$T/build/src/mangoapp" "$BUILD/mangoapp"
rm -rf "$T"
rmdir "$R/t" 2>/dev/null || true
[[ "$MADE_RESOLV" == 0 ]] || rm -f "$R/etc/resolv.conf"
log "OK: $BUILD/mangoapp"
