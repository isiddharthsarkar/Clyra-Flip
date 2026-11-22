# Clyra-Flip Kernel — Build & Flashable Zip Guide

Build the Linux 6.6.144 "Clyra-Flip" kernel on your own Linux machine and package it into a flashable AnyKernel3 zip for TWRP/OrangeFox recovery.

---

## Overview

| Item | Value |
|------|-------|
| Kernel | Linux 6.6.144 |
| Kernel name | Clyra-Flip |
| Devices | ruan (Redmi Note 12 5G), dizi (Redmi Note 12 WiFi) |
| Android versions | 14 (GKI 2.0), 15 (GKI 3.0), 16 (GKI 3.1), 17 (GKI 4.0) |
| Compiler | AOSP clang-r416183b |
| Cross toolchain | aarch64-linux-gnu-, arm-linux-gnueabi- |
| Boot image header | v3 |
| Flash method | AnyKernel3 zip (magiskboot) via TWRP / OrangeFox |

---

## Step 1 — Install Build Dependencies

On Debian/Ubuntu-based distros:

```sh
sudo apt-get update
sudo apt-get install -y \
    build-essential \
    git \
    curl \
    wget \
    bc \
    bison \
    flex \
    libssl-dev \
    libncurses5-dev \
    libncursesw5-dev \
    xz-utils \
    tar \
    gzip \
    unzip \
    zip \
    python3 \
    python3-pip \
    aarch64-linux-gnu-gcc \
    arm-linux-gnueabi-gcc \
    rsync \
    file
```

On Fedora/RHEL-based distros:

```sh
sudo dnf install -y \
    @development-tools \
    git \
    curl \
    wget \
    bc \
    bison \
    flex \
    openssl-devel \
    ncurses-devel \
    xz \
    tar \
    gzip \
    unzip \
    zip \
    python3 \
    aarch64-linux-gnu-gcc \
    arm-linux-gnueabi-gcc \
    rsync \
    file
```

Verify the cross compilers are present:

```sh
which aarch64-linux-gnu-gcc arm-linux-gnueabi-gcc
```

---

## Step 2 — Clone the Repository

```sh
git clone https://github.com/isiddharthsarkar/Clyra-Flip.git
cd Clyra-Flip
git checkout main
```

---

## Step 3 — Download AOSP clang-r416183b

The kernel **must** be built with clang-r416183b for KMI compatibility (stock vendor modules require matching symbol CRCs).

Download the prebuilt clang from Google's Android CI:

```sh
cd ~
wget https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/tags/clang-r416183b.tar.gz
tar -xzf clang-r416183b.tar.gz
```

Or if the direct archive URL changes, clone the prebuilts repo and check out the specific version:

```sh
# Alternative: shallow clone prebuilts (large, ~2GB+)
git clone --depth 1 https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86 ~/clang-prebuilts
cd ~/clang-prebuilts
# checkout clang-r416183b branch/tag
```

Verify clang works:

```sh
~/clang-r416183b/bin/clang --version
```

You should see output like: `clang version 14.0.6 (...)`

---

## Step 4 — Choose Your Device and Android Version

| Device | Codename | Variant |
|--------|----------|---------|
| ruan | Redmi Note 12 5G | 5G (SM7435) |
| dizi | Redmi Note 12 WiFi | WiFi-only |

| Android | GKI Version | Config file |
|---------|-------------|-------------|
| 14 | GKI 2.0 | `build.config.ruan.android14` / `build.config.dizi.android14` |
| 15 | GKI 3.0 | `build.config.ruan.android15` / `build.config.dizi.android15` |
| 16 | GKI 3.1 | `build.config.ruan.android16` / `build.config.dizi.android16` |
| 17 | GKI 4.0 | `build.config.ruan.android17` / `build.config.dizi.android17` |

---

## Step 5 — Build the Kernel

From the `Clyra-Flip` directory:

```sh
# Example: Build for ruan (Redmi Note 12 5G), Android 16
CLANG_DIR=~/clang-r416183b ./build.sh ~/clang-r416183b ruan android16

# Example: Build for dizi (Redmi Note 12 WiFi), Android 15
CLANG_DIR=~/clang-r416183b ./build.sh ~/clang-r416183b dizi android15

# Example: Build for ruan, Android 17
CLANG_DIR=~/clang-r416183b ./build.sh ~/clang-r416183b ruan android17
```

The build script will:
1. Validate clang-r416183b is present
2. Source the device/Android build config
3. Generate the kernel config (`gki_defconfig` + device config)
4. Build `Image`, modules, and DTBs

Output goes to: `out-ruan66/` (or `out-dizi66/`)

**Verify build succeeded:**

```sh
ls -la out-ruan66/arch/arm64/boot/Image
ls -la out-ruan66/arch/arm64/boot/dts/vendor/qcom/*.dtb
```

Expected files:
- `out-ruan66/arch/arm64/boot/Image` — kernel image
- `out-ruan66/arch/arm64/boot/dts/vendor/qcom/ruan.dtb` — ruan DTB
- `out-ruan66/arch/arm64/boot/dts/vendor/qcom/dizi.dtb` — dizi DTB

---

## Step 6 — Package the Flashable Zip

The `flashable/package.sh` script copies the built `Image` and DTBs into the AnyKernel3 zip structure:

```sh
# For ruan
./flashable/package.sh out-ruan66

# For dizi
./flashable/package.sh out-dizi66
```

This produces:

```
clyra-flip-kernel-ruan-6.6.144-Clyra-Flip.zip
```

or

```
clyra-flip-kernel-dizi-6.6.144-Clyra-Flip.zip
```

**Verify the zip contents:**

```sh
unzip -l clyra-flip-kernel-ruan-6.6.144-Clyra-Flip.zip
```

You should see:
- `Image` — your built kernel (not a placeholder)
- `dtb/ruan.dtb` or `dtb/dizi.dtb` — your built DTB
- `anykernel.sh` — AnyKernel3 installer
- `tools/magiskboot` — boot image patcher
- `META-INF/com/google/android/update-binary`
- `META-INF/com/google/android/updater-script`

---

## Step 7 — Flash on Your Device

### Prerequisites
- Your device must have an unlocked bootloader
- TWRP or OrangeFox recovery installed
- A full backup of your current boot image (just in case)

### Flash

1. Copy the zip to your phone's internal storage or SD card
2. Reboot to recovery: `adb reboot recovery`
3. In TWRP/OrangeFox: **Install** → select the zip → swipe to flash
4. Reboot system

### What the zip does

The AnyKernel3 installer:
1. Detects your boot partition slot (A/B or non-A/B) from `/proc/bootconfig`
2. Patches `boot.img` (and `vendor_boot.img` if present) using `magiskboot`
3. Replaces the kernel with the Clyra-Flip Image
4. Preserves the original RAMDISK
5. Supports Magisk retention (if Magisk is already installed)

---

## Step 8 — Troubleshooting

| Problem | Solution |
|---------|----------|
| `clang not found` | Set `CLANG_DIR` to the clang-r416183b directory containing `bin/clang` |
| `aarch64-linux-gnu-gcc: command not found` | Install the cross-compiler package (`aarch64-linux-gnu-gcc`) |
| Build fails with config errors | Make sure you sourced the correct `build.config.<device>.android<NN>` |
| Zip contains placeholder Image/DTB | You ran `package.sh` without building first — build, then repackage |
| Bootloop after flash | Restore stock boot.img via fastboot: `fastboot flash boot stock-boot.img` |

---

## Quick Reference

```sh
# One-liner for ruan + Android 16
CLANG_DIR=~/clang-r416183b ./build.sh ~/clang-r416183b ruan android16 && ./flashable/package.sh out-ruan66

# One-liner for dizi + Android 15
CLANG_DIR=~/clang-r416183b ./build.sh ~/clang-r416183b dizi android15 && ./flashable/package.sh out-dizi66
```

---

## ROM Compatibility

The same kernel binary works with any Android-based ROM because they all use the same Android kernel interfaces:

- **HyperOS** (Xiaomi's stock ROM)
- **AOSP** (custom ROMs like LineageOS, Pixel Experience, etc.)
- **OneUI 8+** (Samsung)
- **ColorOS** (OPPO/Realme)
- **OxygenOS** (OnePlus)

No device-specific changes needed — just flash the same zip.

---

## Support

- Repository: https://github.com/isiddharthsarkar/Clyra-Flip
- Issues: https://github.com/isiddharthsarkar/Clyra-Flip/issues