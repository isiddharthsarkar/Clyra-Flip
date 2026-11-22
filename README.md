# Clyra-Flip

Custom Android kernel for the Xiaomi **ruan** platform
(Redmi Note 13 4G / POCO M6 Pro 4G family, SM7435), branded **Clyra-Flip**.

## Tree origin

This tree is a fork of [noble6/kernel_xiaomi_ruan](https://github.com/noble6/kernel_xiaomi_ruan)
on branch `ruan-6.6`, which is derived from the Android common kernel for
Qualcomm SM8x5x/SM7x5x platforms. The merge base in this repo is
commit `36d715572` ("ruan: Search the module image without memmem") of that
repository.

## Kernel version

Linux stable **6.6.144**, released as **6.6.144-Clyra-Flip** (set via
`EXTRAVERSION = -Clyra-Flip` in the top-level Makefile; `NAME = "Clyra-Flip"`).

## Device support

Ruan-specific code carried in this tree:

- `drivers/misc/ruan_bringup.c` — bring-up aid (`ruan_bringup.panic_after=`)
- `drivers/power/supply/qti_battery_charger_ruan.c` — ruan battery charger driver
- `arch/arm64/configs/vendor/ruan_GKI.config` — GKI config for ruan
- `ruan/mkimg66.sh` — test-image script for booting the 6.6 kernel on an
  installed ROM (no ROM build required)

## Configuration

```
make ARCH=arm64 ruan_GKI_vendor_defconfig
```

The vendor config lives at `arch/arm64/configs/vendor/ruan_GKI.config`.

## Building

Requires the Android kernel build toolchain (LLVM/clang + GNU ld or lld), e.g.:

```
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi- CC=clang LD.lld=ld.lld -j$(nproc)
```

Boot image: `arch/arm64/boot/Image`; DTBs under `arch/arm64/boot/dts/vendor/qcom/`.

See `ruan/mkimg66.sh` for the ruan test-image workflow (boot66.img,
vendor_boot66.img, dtbo66.img).

## License

GNU General Public License v2.0 — see `COPYING`. Individual files may carry
their own licenses (SPDX headers apply).
