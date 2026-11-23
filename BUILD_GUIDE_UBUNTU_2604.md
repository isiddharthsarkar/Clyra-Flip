# Clyra-Flip Kernel Build Guide — Ubuntu 26.04.1

Build the Linux 6.6.162 "Clyra-Flip" kernel and create a universal flashable
AnyKernel3 zip on Ubuntu 26.04.1. The resulting zip auto-detects device
(ruan/dizi) AND Android version (14/15/16/17) at flash time — just flash and
reboot, no choices needed.

---

## What You'll Build

| Item | Value |
|------|-------|
| Kernel | Linux 6.6.162 |
| Kernel name | Clyra-Flip |
| Devices | ruan (Redmi Note 12 5G), dizi (Redmi Note 12 WiFi) |
| Android versions | 14 (GKI 2.0), 15 (GKI 3.0), 16 (GKI 3.1), 17 (GKI 4.0) |
| Build combinations | 8 (2 devices × 4 Android versions) |
| Compiler | AOSP clang-r416183b |
| Cross toolchain | aarch64-linux-gnu-, arm-linux-gnueabi- |
| Output | Universal flashable zip: `clyra-flip-kernel-universal-6.6.162-Clyra-Flip.zip` |

---

## Step 1 — Update Ubuntu and Install Build Dependencies

```sh
# Update package lists
sudo apt-get update

# Install all required build tools and cross-compilers
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
    file \
    make \
    gcc \
    clang \
    llvm \
    lld
```

Verify the cross compilers are installed:

```sh
which aarch64-linux-gnu-gcc arm-linux-gnueabi-gcc
```

Expected output:
```
/usr/bin/aarch64-linux-gnu-gcc
/usr/bin/arm-linux-gnueabi-gcc
```

Also verify standard tools:

```sh
which make gcc clang zip unzip
```

---

## Step 2 — Clone the Clyra-Flip Repository

```sh
# Clone the repo
git clone https://github.com/isiddharthsarkar/Clyra-Flip.git
cd Clyra-Flip

# Make sure you're on main
git checkout main
```

---

## Step 3 — Download AOSP clang-r416183b

The kernel **must** be built with clang-r416183b for KMI compatibility
(stock vendor modules require matching symbol CRCs). Ubuntu's `clang`
package is a different version and won't work.

```sh
# Create a tools directory
mkdir -p ~/clyra-tools
cd ~/clyra-tools

# Download clang-r416183b from Google's Android CI
wget https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/tags/clang-r416183b.tar.gz

# Extract
tar -xzf clang-r416183b.tar.gz

# Verify clang works
~/clyra-tools/clang-r416183b/bin/clang --version
```

You should see output like:
```
clang version 14.0.6 (...)
```

If the direct archive URL is unavailable, clone the prebuilts repo instead:

```sh
git clone --depth 1 https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86 ~/clyra-tools/clang-prebuilts
cd ~/clyra-tools/clang-prebuilts
git checkout clang-r416183b
```

---

## Step 4 — Build All 8 Kernel Combinations

Build each device × Android version combination. Each build produces a
separate output directory (`out-ruan66.android14`, etc.).

```sh
cd ~/Clyra-Flip
CLANG_DIR=~/clyra-tools/clang-r416183b

# Build all 8 combinations
for dev in ruan dizi; do
  for ver in android14 android15 android16 android17; do
    echo "========================================"
    echo "Building $dev $ver"
    echo "========================================"
    ./build.sh $CLANG_DIR $dev $ver
  done
done
```

Or build individually:

```sh
CLANG_DIR=~/clyra-tools/clang-r416183b

# ruan (Redmi Note 12 5G)
./build.sh $CLANG_DIR ruan android14
./build.sh $CLANG_DIR ruan android15
./build.sh $CLANG_DIR ruan android16
./build.sh $CLANG_DIR ruan android17

# dizi (Redmi Note 12 WiFi)
./build.sh $CLANG_DIR dizi android14
./build.sh $CLANG_DIR dizi android15
./build.sh $CLANG_DIR dizi android16
./build.sh $CLANG_DIR dizi android17
```

### Verify Build Output

```sh
# Check that all 8 Image files exist
ls -la out-ruan66.android14/arch/arm64/boot/Image
ls -la out-ruan66.android15/arch/arm64/boot/Image
ls -la out-ruan66.android16/arch/arm64/boot/Image
ls -la out-ruan66.android17/arch/arm64/boot/Image
ls -la out-dizi66.android14/arch/arm64/boot/Image
ls -la out-dizi66.android15/arch/arm64/boot/Image
ls -la out-dizi66.android16/arch/arm64/boot/Image
ls -la out-dizi66.android17/arch/arm64/boot/Image

# Check DTBs exist
ls -la out-ruan66.android16/arch/arm64/boot/dts/vendor/qcom/*.dtb
ls -la out-dizi66.android16/arch/arm64/boot/dts/vendor/qcom/*.dtb
```

Expected kernel release: `6.6.162-Clyra-Flip`

```sh
cat out-ruan66.android16/include/config/kernel.release
```

---

## Step 5 — Package the Universal Flashable Zip

Run the packager from the repo root. It looks for `out-*` directories in
the current directory.

```sh
cd ~/Clyra-Flip
./flashable/package.sh .
```

This creates:

```
clyra-flip-kernel-universal-6.6.162-Clyra-Flip.zip
```

The zip contains:
- `Image.ruan.android14` through `Image.ruan.android17`
- `Image.dizi.android14` through `Image.dizi.android17`
- `dtb/ruan.dtb`, `dtb/dizi.dtb`
- `anykernel.sh` — auto-detecting installer
- `tools/magiskboot`, `tools/ak3-core.sh`, `tools/busybox`

Verify the zip contents:

```sh
unzip -l clyra-flip-kernel-universal-6.6.162-Clyra-Flip.zip | head -30
```

---

## Step 6 — Flash on Your Device

### Prerequisites
- Unlocked bootloader on your Xiaomi device
- TWRP or OrangeFox recovery installed
- Full backup of your current boot image (just in case)

### Flash

```sh
# Copy the zip to your phone's internal storage
adb push clyra-flip-kernel-universal-6.6.162-Clyra-Flip.zip /sdcard/

# Reboot to recovery
adb reboot recovery
```

Then in TWRP/OrangeFox recovery:
1. **Install** → select `clyra-flip-kernel-universal-6.6.162-Clyra-Flip.zip`
2. Swipe to flash
3. **Reboot** to system

### What Happens During Flash

`anykernel.sh` automatically:
1. Detects your device (`ro.product.device` → ruan or dizi)
2. Detects your Android version (`ro.build.version.release` → 14/15/16/17)
3. Selects the matching `Image.<device>.android<NN>`
4. Flashes to the active boot slot (detects A/B slot from `/proc/bootconfig`)
5. Preserves the original RAMDISK
6. Supports Magisk retention if Magisk is installed

**No choices needed — just flash and reboot.**

---

## One-Liner Summary

```sh
# Install deps
sudo apt-get update && sudo apt-get install -y build-essential git curl wget \
    bc bison flex libssl-dev libncurses5-dev libncursesw5-dev xz-utils \
    tar gzip unzip zip python3 python3-pip aarch64-linux-gnu-gcc \
    arm-linux-gnueabi-gcc rsync file make gcc clang llvm lld

# Download clang
mkdir -p ~/clyra-tools && cd ~/clyra-tools
wget https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/tags/clang-r416183b.tar.gz
tar -xzf clang-r416183b.tar.gz

# Clone repo
git clone https://github.com/isiddharthsarkar/Clyra-Flip.git
cd Clyra-Flip

# Build all 8 combinations
CLANG_DIR=~/clyra-tools/clang-r416183b
for dev in ruan dizi; do
  for ver in android14 android15 android16 android17; do
    ./build.sh $CLANG_DIR $dev $ver
  done
done

# Package universal zip
./flashable/package.sh .

# Flash
adb push clyra-flip-kernel-universal-6.6.162-Clyra-Flip.zip /sdcard/
adb reboot recovery
```

---

## Troubleshooting on Ubuntu 26.04.1

| Problem | Solution |
|---------|----------|
| `aarch64-linux-gnu-gcc: command not found` | Install: `sudo apt-get install aarch64-linux-gnu-gcc arm-linux-gnueabi-gcc` |
| `clang not found` or wrong version | Use clang-r416183b from `~/clyra-tools/clang-r416183b/bin/clang`, not Ubuntu's clang |
| `permission denied` on build | Make sure `build.sh` is executable: `chmod +x build.sh` |
| No output directories | Check that `build.sh` completed without errors for each combination |
| Zip doesn't detect device | Ensure you're in TWRP/OrangeFox recovery; `getprop` must work |
| Bootloop after flash | Restore stock boot.img: `fastboot flash boot stock-boot.img` |
| `zip` command not found | Install: `sudo apt-get install zip` |

---

## ROM Compatibility

The same kernel works with any Android-based ROM because they all use the
same Android kernel interfaces:

- **HyperOS** (Xiaomi stock)
- **AOSP** custom ROMs (LineageOS, Pixel Experience, etc.)
- **OneUI 8+** (Samsung)
- **ColorOS** (OPPO/Realme)
- **OxygenOS** (OnePlus)

No device-specific changes needed — the universal zip handles ruan, dizi,
and all Android versions automatically.

---

## Files Created on Ubuntu

| Path | Description |
|------|-------------|
| `~/clyra-tools/clang-r416183b/` | AOSP clang-r416183b compiler |
| `~/Clyra-Flip/` | Kernel source tree |
| `out-ruan66.android14/..17/` | ruan build outputs |
| `out-dizi66.android14/..17/` | dizi build outputs |
| `clyra-flip-kernel-universal-6.6.162-Clyra-Flip.zip` | Universal flashable zip |

---

## Support

- Repository: https://github.com/isiddharthsarkar/Clyra-Flip
- Issues: https://github.com/isiddharthsarkar/Clyra-Flip/issues