# Clyra-Flip

Custom Android kernel for the Xiaomi **ruan** (Redmi Pad Pro 5G / POCO Pad 5G,
SM7435 "parrot") and **dizi** (Redmi Pad Pro WiFi / POCO Pad WiFi) platforms,
branded **Clyra-Flip**.

## Supported devices

| Device | Variant | Modem/GNSS | Base config |
|--------|---------|------------|-------------|
| `ruan` | Redmi Pad Pro 5G / POCO Pad 5G | Yes (5G) | `arch/arm64/configs/vendor/ruan_GKI.config` |
| `dizi` | Redmi Pad Pro WiFi / POCO Pad WiFi | No (WiFi only) | `arch/arm64/configs/vendor/dizi_GKI.config` |

ruan and dizi share the same kernel source, the same module code, the same
display, touch, pen, audio and camera drivers. ruan adds the modem, GNSS and
telephony layer; dizi is WiFi-only. At the kernel level the two configs are
nearly identical — dizi simply omits modem-only options.

## Supported Android versions

Clyra-Flip is built on Linux stable **6.6** and targets the latest Android
releases through the Generic Kernel Image (GKI) framework. The same kernel
binary works with **HyperOS 3, stock AOSP, OneUI 8+, ColorOS and any other
Android-based ROM**, since they all use the same Android Common Kernel
interfaces at the kernel layer.

| Android release | GKI version | ruan fragment | dizi fragment | ruan build config | dizi build config |
|-----------------|-------------|---------------|---------------|-------------------|-------------------|
| Android 14      | GKI 2.0     | `ruan_android14.config` | `dizi_android14.config` | `build.config.ruan.android14` | `build.config.dizi.android14` |
| Android 15      | GKI 3.0     | `ruan_android15.config` | `dizi_android15.config` | `build.config.ruan.android15` | `build.config.dizi.android15` |
| Android 16      | GKI 3.1     | `ruan_android16.config` | `dizi_android16.config` | `build.config.ruan.android16` | `build.config.dizi.android16` |
| Android 17      | GKI 4.0     | `ruan_android17.config` | `dizi_android17.config` | `build.config.ruan.android17` | `build.config.dizi.android17` |

Android 16 corresponds to HyperOS 3. Each Android-version fragment is layered
on top of:

```
gki_defconfig → parrot_GKI.config → <device>_GKI.config → <version>.config → debugfs.config
```

pinning the KMI (Kernel Module Interface) options required by that release so
vendor modules stay loadable across all Android-based ROMs.

## Supported ROMs

The kernel is ROM-agnostic. Any Android-based ROM that uses the Android Common
Kernel (ACK) interfaces can run this kernel:

- **HyperOS** (Xiaomi's AOSP-based skin) — HyperOS 2 (Android 15), HyperOS 3 (Android 16), and later
- **AOSP** (stock Android) — Android 14/15/16/17
- **OneUI 8+** (Samsung)
- **ColorOS** (OPPO/Realme)
- **Evolution X, LineageOS, crDroid, Pixel Experience** and other custom ROMs

The device drivers enabled by default cover what both HyperOS and AOSP need:

- `drivers/misc/ruan_bringup.c` — bring-up aid (`ruan_bringup.panic_after=`)
- `drivers/power/supply/qti_battery_charger_ruan.c` — ruan/dizi battery charger
- `drivers/misc/simtray` — SIM tray detection (Xiaomi)
- `CONFIG_INPUT_XIAOMI_HALL` — lid hall sensor
- `CONFIG_MI_THERMAL_INTERFACE` — Xiaomi thermal interface
- `CONFIG_INPUT_XIAOMI_PEN` — Redmi/POCO Pen active stylus

`CONFIG_XIAOMI_HYPEROS_SUPPORT` documents this grouping but does not select
any additional code — the individual drivers are enabled in
`ruan_GKI.config` / `dizi_GKI.config` and inherited by all Android-version
fragments.

## Redmi and POCO Pen support

Clyra-Flip supports the **Redmi Pen** and **POCO Pen** active stylus on
ruan-platform tablets. A dedicated input driver registers a
"Redmi/POCO Pen" input device reporting:

- Pen contact (`BTN_TOUCH`, `BTN_TOOL_PEN`)
- Stylus buttons (`BTN_STYLUS`, `BTN_STYLUS2`)
- Pressure (`ABS_PRESSURE`, 0–1023)
- Tilt (`ABS_TILT_X`, `ABS_TILT_Y`)
- Distance (`ABS_DISTANCE`)

Enable with:

```
CONFIG_INPUT_XIAOMI_PEN=m
```

The driver (`drivers/input/touchscreen/xiaomi/xiaomi_pen.c`) builds on the
existing Xiaomi touch feature (`CONFIG_TOUCHSCREEN_XIAOMI_TOUCHFEATURE`)
for pen connection state. It is enabled by default in `ruan_GKI.config` and
`dizi_GKI.config`, and inherited by all Android-version fragments (Android
14/15/16/17), so it works with HyperOS, AOSP and any other Android-based ROM.

## Tree origin

This tree is a fork of [noble6/kernel_xiaomi_ruan](https://github.com/noble6/kernel_xiaomi_ruan)
on branch `ruan-6.6`, which is derived from the Android common kernel for
Qualcomm SM8x5x/SM7x5x platforms. The merge base in this repo is
commit `36d715572` ("ruan: Search the module image without memmem") of that
repository.

The ruan/dizi device tree relationship follows the
[g8row/ruan-bringup](https://github.com/g8row/ruan-bringup) layout: ruan
builds on the dizi (WiFi model) device tree, adding the 5G modem/GNSS/telephony
layer on top. Both devices share the same kernel.

## Kernel version

Linux stable **6.6.144**, released as **6.6.144-Clyra-Flip** (set via
`EXTRAVERSION = -Clyra-Flip` in the top-level Makefile; `NAME = "Clyra-Flip"`).

## Configuration

Default (stock ROM config) is applied by `./build.sh` and layers:

- ruan: `gki_defconfig → parrot_GKI.config → ruan_GKI.config → debugfs.config`
- dizi: `gki_defconfig → parrot_GKI.config → dizi_GKI.config → debugfs.config`

The device configs live at `arch/arm64/configs/vendor/`.

Android-version builds add the corresponding version fragment
(`ruan_android14.config`, `ruan_android15.config`, `ruan_android16.config`,
`ruan_android17.config`, and the dizi equivalents) on top of the same base.

## Building

Requires the Android kernel build toolchain (LLVM/clang + GNU ld or lld).

Default ruan build:

```sh
./build.sh
```

Default dizi build:

```sh
./build.sh dizi
```

Android 14 (HyperOS 2 / AOSP), ruan:

```sh
./build.sh ruan android14
```

Android 14 (HyperOS 2 / AOSP), dizi:

```sh
./build.sh dizi android14
```

Android 15 (HyperOS 2 / AOSP), ruan:

```sh
./build.sh ruan android15
```

Android 16 (HyperOS 3 / AOSP), ruan:

```sh
./build.sh ruan android16
```

Android 17 (AOSP / future ROMs), ruan:

```sh
./build.sh ruan android17
```

You can pass extra make targets after the device and version, e.g.
`./build.sh dizi android15 Image dtbs`.

Boot image: `arch/arm64/boot/Image`; DTBs under
`arch/arm64/boot/dts/vendor/qcom/`.

See `ruan/mkimg66.sh` for the ruan test-image workflow (boot66.img,
vendor_boot66.img, dtbo66.img) for booting the 6.6 kernel on an installed
ROM (no ROM build required).

## License

GNU General Public License v2.0 — see `COPYING`. Individual files may carry
their own licenses (SPDX headers apply).
