#!/usr/bin/env bash
# Loadout on every image: the engine (hub.py, with the store side in
# loadout.py), its commands, and the Decky plugin that is its front end (the
# Thor's bottom screen has its own page too). Called by each apply-overlays
# script. Loadout was the Emulator Hub; its state and launchers keep the old
# names so installs, shortcuts and ES-DE carry over.
#   install-hub.sh <rootfs> [<home of the default user in the image>]
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
R="${1:?rootfs}"
HOME_DST="${2:-}"
OVL="${ROOT}/steamos-overlay"
SRC="${ROOT}/external-and-mods/Decky/common/loadout"

# Odin 3 own image: no Loadout (no commands, no store side, no Decky plugin).
# hub.py and its catalog stay as an internal engine only: the login service
# steamos-arm-video-accel runs "hub.py video-accel-sync" to give Flatpak apps
# (Firefox and others) the hardware video decoder.
install -d -m0755 "$R/usr/lib/steamos-arm/hub"
install -m0755 "$OVL/usr/lib/steamos-arm/hub/hub.py" "$R/usr/lib/steamos-arm/hub/hub.py"
install -m0644 "$OVL/usr/lib/steamos-arm/hub/catalog.json" "$R/usr/lib/steamos-arm/hub/catalog.json"
rm -f "$R/usr/bin/steamos-arm-hub" "$R/usr/bin/loadout" "$R/usr/lib/steamos-arm/hub/loadout.py"
rm -rf "$R/usr/share/steamos-odin/decky-plugins/emulator-hub" "$R/usr/share/steamos-odin/decky-plugins/loadout"
if [[ -n "$HOME_DST" && -d "$HOME_DST" ]]; then
  rm -rf "$HOME_DST/homebrew/plugins/emulator-hub" "$HOME_DST/homebrew/plugins/loadout"
fi
# Steam's own power controls (Performance Profile, TDP, GPU clock, charge
# limit) relayed to the device daemon; every image, it finds konkrd/odin3d.
install -m0644 "$OVL/usr/lib/steamos-arm/power_limits.py" "$R/usr/lib/steamos-arm/power_limits.py"
install -m0755 "$OVL/usr/lib/steamos-arm/steamos-arm-power" "$R/usr/lib/steamos-arm/steamos-arm-power"
install -D -m0644 "$OVL/usr/share/dbus-1/system.d/org.steamos_arm.Power.conf" "$R/usr/share/dbus-1/system.d/org.steamos_arm.Power.conf"
install -D -m0644 "$OVL/usr/lib/systemd/system/steamos-arm-power.service" "$R/usr/lib/systemd/system/steamos-arm-power.service"
install -D -m0644 "$OVL/usr/share/steamos-manager/remotes.d/50-steamos-arm.toml" "$R/usr/share/steamos-manager/remotes.d/50-steamos-arm.toml"
mkdir -p "$R/usr/lib/systemd/system/multi-user.target.wants"
ln -sfn ../steamos-arm-power.service "$R/usr/lib/systemd/system/multi-user.target.wants/steamos-arm-power.service"
# gamescope's CAP_SYS_NICE, re-applied at boot if a copy or update dropped it.
install -D -m0644 "$OVL/usr/lib/systemd/system/steamos-arm-gamescope-caps.service" "$R/usr/lib/systemd/system/steamos-arm-gamescope-caps.service"
mkdir -p "$R/usr/lib/systemd/system/graphical.target.wants"
ln -sfn ../steamos-arm-gamescope-caps.service "$R/usr/lib/systemd/system/graphical.target.wants/steamos-arm-gamescope-caps.service"
for gs in "$R/usr/bin/gamescope" "$R/usr/local/bin/gamescope"; do
  [[ -x "$gs" ]] && setcap cap_sys_nice=eip "$gs"
done
echo "power relay and video-decode engine installed (no Loadout)"
