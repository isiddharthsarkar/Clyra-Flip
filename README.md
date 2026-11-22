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

### Quick reference

| Task | Command |
|------|---------|
| Default ruan build (stock ROM) | `./build.sh` |
| Default dizi build (stock ROM) | `./build.sh dizi` |
| Android 14 / HyperOS 2, ruan | `./build.sh ruan android14` |
| Android 14 / HyperOS 2, dizi | `./build.sh dizi android14` |
| Android 15 / HyperOS 2, ruan | `./build.sh ruan android15` |
| Android 15 / HyperOS 2, dizi | `./build.sh dizi android15` |
| Android 16 / HyperOS 3, ruan | `./build.sh ruan android16` |
| Android 16 / HyperOS 3, dizi | `./build.sh dizi android16` |
| Android 17 / AOSP, ruan | `./build.sh ruan android17` |
| Android 17 / AOSP, dizi | `./build.sh dizi android17` |

### Firmware requirements

The tablet should run **HyperOS OS3.0.303.0 or newer** (Android 16 firmware)
before flashing this kernel. The ROM reuses the firmware partitions (modem,
bootloader, TrustZone) already on the tablet. Never relock the bootloader
while this kernel is installed.

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

## Build Requirements

Clyra-Flip must be built with **AOSP clang** (tested with `clang-r416183b`,
the compiler of the GKI builds). Another compiler changes symbol CRCs and
stock vendor modules will no longer load. Set `CLANG_DIR` or pass the clang
directory as the first argument to `build.sh`.

A `CONFIG_LOCALVERSION_AUTO=y` is required: `CONFIG_MODULE_SCMVERSION`
depends on it and it adds a field to `struct module`, so turning it off
breaks `module_layout` for every stock module. `CONFIG_HZ` stays 250 because
stock vendor modules have it compiled in.

```sh
# With clang in a custom location
CLANG_DIR=/path/to/clang-r416183b ./build.sh ruan android16

# Or pass the clang directory as the first argument
./build.sh /path/to/clang-r416183b ruan android16
```

## Building

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

Android 17 (AOSP / future ROMs), dizi:

```sh
./build.sh dizi android17
```

You can pass extra make targets after the device and version, e.g.
`./build.sh dizi android15 Image dtbs`.

Boot image: `arch/arm64/boot/Image`; DTBs under
`arch/arm64/boot/dts/vendor/qcom/`.

## Flashing via TWRP / OrangeFox

The `flashable/` directory contains an **AnyKernel3**-compatible flashable
zip template for packaging the built kernel into a TWRP/OrangeFox-installable
zip:

```
flashable/
├── anykernel.sh
├── package.sh
├── README.md
├── ramdisk/
├── patch/
├── modules/
├── tools/
│   ├── ak3-core.sh
│   ├── magiskboot
│   └── busybox
└── META-INF/
    └── com/google/android/
        ├── update-binary
        └── updater-script
```

AnyKernel3 patches the device's boot image at flash time using `magiskboot`,
preserving the original ramdisk structure and supporting Magisk retention.

### Package the flashable zip

After building the kernel:

```sh
# ruan (5G model)
./flashable/package.sh out-ruan66

# dizi (WiFi model)
./flashable/package.sh out-dizi66
```

The package script copies the kernel `Image` and DTBs from the build output
into the AnyKernel3 zip structure and creates:
```
clyra-flip-kernel-ruan-6.6.144-Clyra-Flip.zip
```

### Flash

1. Copy the `.zip` to your device's internal storage or USB-OTG drive.
2. Reboot to TWRP / OrangeFox recovery.
3. **Install** → select the zip → swipe to flash.
4. (Optional) Wipe cache/dalvik.
5. Reboot to system.

AnyKernel3 will auto-detect your device (ruan/dizi), dump the current
`boot.img` from the active slot, replace the kernel with Clyra-Flip, repack
and flash to both A/B slots. The `vendor_boot` partition is also patched with
the new DTB if included.

See `ruan/mkimg66.sh` for the ruan test-image workflow (boot66.img,
vendor_boot66.img, dtbo66.img) for booting the 6.6 kernel on an installed
ROM (no ROM build required).

## KernelSU + susfs

Clyra-Flip includes **KernelSU** — a kernel-level root solution for Android —
with **susfs** (SU Filesystem) support enabled by default.

| Feature | Config | Default |
|---------|--------|---------|
| KernelSU core | `CONFIG_KERNEL_SU` | `y` |
| susfs filesystem | `CONFIG_KSU_SUSFS` | `y` |
| Root hide | `CONFIG_KSU_HIDE` | `y` |

KernelSU provides root access at the kernel level without modifying the boot
ramdisk. The susfs virtual filesystem (`/susfs`) exposes control files
(`root`, `unroot`, `is_root`, `hide`, `unhide`, `version`) that userspace
daemons can use to manage root status.

To enable/disable root hide from a root shell:

```sh
echo 1 > /susfs/hide    # hide root from detection apps
echo 1 > /susfs/unhide  # show root again
```

KernelSU works with all supported ROMs (HyperOS, AOSP, OneUI 8+, ColorOS,
etc.) because it hooks at the kernel credential layer, below the ROM level.

## CAF / Qualcomm support

Clyra-Flip includes **CAF (Code Aurora Forum)** Qualcomm platform support
for the SM7435 SoC used by ruan and dizi:

| Subsystem | Config | Description |
|-----------|--------|-------------|
| QCOM SMEM | `CONFIG_QCOM_SMEM` | Shared memory for inter-processor comms |
| QCOM SMD RPM | `CONFIG_QCOM_SMD_RPM` | Shared memory doorbell for RPM |
| QCOM SPMI | `CONFIG_QCOM_SPMI_*` | System Power Management Interface |
| QCOM PDC | `CONFIG_QCOM_PDC` | Power Debug Controller |
| QCOM RPMH | `CONFIG_QCOM_RPMH_*` | Runtime Power Management Hierarchy |
| QCOM CPR | `CONFIG_QCOM_CPR` | Critical Path Regression |
| QCOM LLCC | `CONFIG_QCOM_LLCC` | Last Level Cache Coherency |
| QCOM QUPV3 I2C | `CONFIG_QCOM_QUPV3_I2C` | Qualcomm Universal Peripheral |
| QCOM PHY | `CONFIG_QCOM_USB_*_PHY` | USB PHY drivers |
| QCOM Clock | `CONFIG_QCOM_CLOCK_*` | Clock controllers |
| QCOM PINCTRL | `CONFIG_PINCTRL_QCOM` | Pin control |
| QCOM GPIO | `CONFIG_GPIO_QCOM` | GPIO controller |
| QCOM Power | `CONFIG_QCOM_POWER` | Power management |
| QCOM ICC | `CONFIG_QCOM_ICC_*` | Interconnect |

These CAF options match the stock Xiaomi firmware's kernel configuration for
the parrot (SM7435) platform, ensuring compatibility with stock vendor
firmware modules and HyperOS.

## License

GNU General Public License v2.0 — see `COPYING`. Individual files may carry
their own licenses (SPDX headers apply).
