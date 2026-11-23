# Clyra-Flip Kernel — Build & Universal Flashable Zip Guide

Build the Linux 6.6.162 "Clyra-Flip" kernel on your own Linux machine and package it into a single universal flashable AnyKernel3 zip that works on **both ruan and dizi, across Android 14/15/16/17** — auto-detecting device and Android version at flash time. Just flash and reboot, no choices needed.

---

## Overview

| Item | Value |
|------|-------|
| Kernel | Linux 6.6.162 |
| Kernel name | Clyra-Flip |
| Devices | ruan (Redmi Note 12 5G), dizi (Redmi Note 12 WiFi) |
| Android versions | 14 (GKI 2.0), 15 (GKI 3.0), 16 (GKI 3.1), 17 (GKI 4.0) |
| Build combinations | 8 (2 devices × 4 Android versions) |
| Compiler | AOSP clang-r416183b |
| Cross toolchain | aarch64-linux-gnu-, arm-linux-gnueabi- |
| Boot image header | v3 |
| Flash method | AnyKernel3 zip (magiskboot) via TWRP / OrangeFox |
| Zip behavior | Auto-detects device + Android version at flash time |

---

## How the Universal Zip Works

The zip contains 8 kernel images:

```
Image.ruan.android14
Image.ruan.android15
Image.ruan.android16
Image.ruan.android17
Image.dizi.android14
Image.dizi.android15
Image.dizi.android16
Image.dizi.android17
dtb/ruan.dtb
dtb/dizi.dtb
anykernel.sh
```

At flash time, `anykernel.sh`:
1. Detects the device (`ro.product.device`, `ro.build.product`, or device-tree)
2. Detects the Android version (`ro.build.version.release` or `ro.build.version.sdk`)
3. Selects the matching `Image.<device>.android<NN>`
4. Flashes it to the active boot slot

**User experience:** Copy zip → reboot to recovery → install → swipe → reboot. No choices.

---

## Step 1 — Install Build Dependencies

**Debian/Ubuntu:**
```sh
sudo apt-get update
sudo apt-get install -y build-essential git curl wget bc bison flex \
    libssl-dev libncurses5-dev libncursesw5-dev xz-utils tar gzip \
    unzip zip python3 python3-pip aarch64-linux-gnu-gcc \
    arm-linux-gnueabi-gcc rsync file
```

**Fedora/RHEL:**
```sh
sudo dnf install -y @development-tools git curl wget bc bison flex \
    openssl-devel ncurses-devel xz tar gzip unzip zip python3 \
    aarch64-linux-gnu-gcc arm-linux-gnueabi-gcc rsync file
```

Verify: `which aarch64-linux-gnu-gcc arm-linux-gnueabi-gcc`

---

## Step 2 — Clone the Repo

```sh
git clone https://github.com/isiddharthsarkar/Clyra-Flip.git
cd Clyra-Flip
git checkout main
```

---

## Step 3 — Download AOSP clang-r416183b

Required for KMI compatibility (stock vendor modules need matching symbol CRCs).

```sh
cd ~
wget https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/tags/clang-r416183b.tar.gz
tar -xzf clang-r416183b.tar.gz
~/clang-r416183b/bin/clang --version
```

---

## Step 4 — Build All 8 Kernel Combinations

Build each device × Android version combination. Each build produces a separate output directory:

```sh
CLANG_DIR=~/clang-r416183b

# ruan (Redmi Note 12 5G)
./build.sh $CLANG_DIR ruan android14   # -> out-ruan66.android14
./build.sh $CLANG_DIR ruan android15   # -> out-ruan66.android15
./build.sh $CLANG_DIR ruan android16   # -> out-ruan66.android16
./build.sh $CLANG_DIR ruan android17   # -> out-ruan66.android17

# dizi (Redmi Note 12 WiFi)
./build.sh $CLANG_DIR dizi android14   # -> out-dizi66.android14
./build.sh $CLANG_DIR dizi android15   # -> out-dizi66.android15
./build.sh $CLANG_DIR dizi android16   # -> out-dizi66.android16
./build.sh $CLANG_DIR dizi android17   # -> out-dizi66.android17
```

Or build all 8 in one loop:

```sh
CLANG_DIR=~/clang-r416183b
for dev in ruan dizi; do
  for ver in android14 android15 android16 android17; do
    echo "=== Building $dev $ver ==="
    ./build.sh $CLANG_DIR $dev $ver
  done
done
```

Verify at least one build succeeded:

```sh
ls -la out-ruan66.android16/arch/arm64/boot/Image
ls -la out-ruan66.android16/arch/arm64/boot/dts/vendor/qcom/*.dtb
```

---

## Step 5 — Package the Universal Flashable Zip

Run the packager from the repo root (it looks for `out-*` directories in the current dir):

```sh
./flashable/package.sh .
```

This creates:

```
clyra-flip-kernel-universal-6.6.162-Clyra-Flip.zip
```

The zip contains all 8 `Image.<device>.android<NN>` files plus both DTBs.

---

## Step 6 — Flash on Any Device, Any Android Version

1. Copy the zip to your phone's internal storage
2. Reboot to TWRP/OrangeFox recovery: `adb reboot recovery`
3. **Install** → select the zip → swipe to flash
4. Reboot to system

`anykernel.sh` auto-detects:
- **Device**: ruan → flashes `Image.ruan.android<NN>` + `dtb/ruan.dtb`
- **Device**: dizi → flashes `Image.dizi.android<NN>` + `dtb/dizi.dtb`
- **Android version**: 14/15/16/17 → selects the matching kernel

No choices needed — just flash and reboot.

---

## Quick Reference

```sh
# Build all 8 combinations
CLANG_DIR=~/clang-r416183b
for dev in ruan dizi; do
  for ver in android14 android15 android16 android17; do
    ./build.sh $CLANG_DIR $dev $ver
  done
done

# Package universal zip
./flashable/package.sh .

# Result: clyra-flip-kernel-universal-6.6.162-Clyra-Flip.zip
```

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `clang not found` | Set `CLANG_DIR` to the clang-r416183b directory containing `bin/clang` |
| `aarch64-linux-gnu-gcc: command not found` | Install `aarch64-linux-gnu-gcc` package |
| No build dirs found by package.sh | Make sure you built all 8 combos; output dirs are `out-<dev>66.android<NN>` |
| Zip doesn't detect device | Make sure you're in TWRP/OrangeFox recovery; `getprop` must work |
| Bootloop after flash | Restore stock boot.img via fastboot: `fastboot flash boot stock-boot.img` |

---

## ROM Compatibility

The same kernel binary works with any Android-based ROM because they all use the same Android kernel interfaces:

- **HyperOS** (Xiaomi's stock ROM)
- **AOSP** (custom ROMs like LineageOS, Pixel Experience, etc.)
- **OneUI 8+** (Samsung)
- **ColorOS** (OPPO/Realme)
- **OxygenOS** (OnePlus)

No device-specific changes needed — the universal zip handles ruan, dizi, and all Android versions automatically.

---

## Support

- Repository: https://github.com/isiddharthsarkar/Clyra-Flip
- Issues: https://github.com/isiddharthsarkar/Clyra-Flip/issues