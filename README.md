# Clyra-Flip

Custom Android kernel for the Xiaomi **ruan** platform
(Redmi Note 13 4G / POCO M6 Pro 4G family, SM7435), branded **Clyra-Flip**.

## Supported Android versions

Clyra-Flip is built on Linux stable **6.6** and targets the latest Android
releases through the Generic Kernel Image (GKI) framework. The same kernel
binary works with both **HyperOS** (Xiaomi's AOSP-based skin) and stock
**AOSP** vendor ramdisks.

| Android release | GKI version | Config fragment | Build config |
|-----------------|-------------|-----------------|--------------|
| Android 14      | GKI 2.0     | `ruan_android14.config` | `build.config.ruan.android14` |
| Android 15      | GKI 3.0     | `ruan_android15.config` | `build.config.ruan.android15` |
| Android 16      | GKI 3.1     | `ruan_android16.config` | `build.config.ruan.android16` |

Each Android-version fragment is layered on top of
`gki_defconfig → parrot_GKI.config → ruan_GKI.config → <version>.config → debugfs.config`,
pinning the KMI (Kernel Module Interface) options required by that release
so vendor modules stay loadable across HyperOS and AOSP builds.

## HyperOS and AOSP compatibility

HyperOS is Xiaomi's Android-based OS; at the kernel layer it uses the same
Android Common Kernel interfaces as AOSP. Clyra-Flip enables the ruan
device drivers both skins rely on:

- `drivers/misc/ruan_bringup.c` — bring-up aid (`ruan_bringup.panic_after=`)
- `drivers/power/supply/qti_battery_charger_ruan.c` — ruan battery charger
- `drivers/misc/simtray` — SIM tray detection (Xiaomi)
- `CONFIG_INPUT_XIAOMI_HALL` — lid hall sensor
- `CONFIG_MI_THERMAL_INTERFACE` — Xiaomi thermal interface

Enable them with `CONFIG_XIAOMI_HYPEROS_SUPPORT=y` (default on).

## Tree origin

This tree is a fork of [noble6/kernel_xiaomi_ruan](https://github.com/noble6/kernel_xiaomi_ruan)
on branch `ruan-6.6`, which is derived from the Android common kernel for
Qualcomm SM8x5x/SM7x5x platforms. The merge base in this repo is
commit `36d715572` ("ruan: Search the module image without memmem") of that
repository.

## Kernel version

Linux stable **6.6.144**, released as **6.6.144-Clyra-Flip** (set via
`EXTRAVERSION = -Clyra-Flip` in the top-level Makefile; `NAME = "Clyra-Flip"`).

## Configuration

Default (stock ROM config) is applied by `./build.sh` and layers:
`gki_defconfig → parrot_GKI.config → ruan_GKI.config → debugfs.config`.

The device config lives at `arch/arm64/configs/vendor/ruan_GKI.config`.

Android-version builds add the corresponding version fragment
(`ruan_android14.config`, `ruan_android15.config`, `ruan_android16.config`)
on top of the same base.

## Building

Requires the Android kernel build toolchain (LLVM/clang + GNU ld or lld).

Default ruan build:

```
./build.sh
```

Android 14 (HyperOS / AOSP):

```
./build.sh android14
```

Android 15 (HyperOS / AOSP):

```
./build.sh android15
```

Android 16 (HyperOS / AOSP):

```
./build.sh android16
```

You can pass extra make targets after the version, e.g.
`./build.sh android15 Image dtbs`.

Boot image: `arch/arm64/boot/Image`; DTBs under
`arch/arm64/boot/dts/vendor/qcom/`.

See `ruan/mkimg66.sh` for the ruan test-image workflow (boot66.img,
vendor_boot66.img, dtbo66.img) for booting the 6.6 kernel on an installed
ROM (no ROM build required).

## License

GNU General Public License v2.0 — see `COPYING`. Individual files may carry
their own licenses (SPDX headers apply).
