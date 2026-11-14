# Mesa "Turnip Gen8 V39" source, built for SteamOS

`MESA_FLAVOR=turnip-v39` in `scripts/build-mesa.sh` builds the same source the
Android driver package "Turnip Gen8 V39 / Turnip v27.0.0-R2" is built from
(https://github.com/StevenMXZ/Adreno-Tools-Drivers/releases), as a normal Linux
Mesa: Turnip and zink for the system (aarch64) and for x86 games under FEX
(x86_64, i386). The Android packages themselves cannot be used on SteamOS.

- Base: upstream Mesa main, commit `c0235eff650720faff05452a06a0a09479b3621f`
  (2026-11-07, version 27.0.0-devel), the day V39 was built. Upstream already
  lists the Odin 3's GPU id (`0xffff44050001`, Adreno 830v1).
- Patches, in order:

| Patch | Source |
|---|---|
| `0001-revert-tu-a6xx-d32s8-early-z-late-z-workaround.patch` | V39's Gen8 recipe reverts Mesa `a70d2af5` first |
| `0002-a8xx-gen8-whitebelyash-turnip-gen8-stack.patch` | `patches/patchsv2/a8xx_gen8.patch` from Adreno-Tools-Drivers at `29028c4`: whitebelyash's `mesa-unified` `turnip/gen8` stack (Mesa commits, MIT) |
| `0003-freedreno-common-increase-shared-mem-size.patch` | the result of that repo's `a8xx_shared_mem.py` (32 KiB to 64 KiB) |
| `0004-ir3-array-to-ssa-resolve-trivial-phi-chains.patch` | carried over from `external-and-mods/mesa/patches` (shader compile crash in Enshrouded and Onimusha), not part of V39 |

Left out on purpose: V39's Android-only parts (gralloc, KGSL, NDK fixes). On
SteamOS Turnip talks to the kernel's `msm` driver, not Qualcomm's KGSL.

This is the plain "Gen8 V39" variant, not "V39 Patched" (extra unmerged
patches, which the release notes say to drop if there are issues).

Switching: `.github/odin3-mesa-flavor` (`stable` = Mesa 26.2.7, or
`turnip-v39`) and `.github/odin3-mesa-reuse-run` (`build`, or the id of a run
whose Mesa artifact to reuse).
