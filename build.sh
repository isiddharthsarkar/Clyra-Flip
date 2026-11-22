#!/bin/bash
# ruan/dizi 6.6 kernel build.
#
# Usage: build.sh [clang-dir] [ruan|dizi] [android14|android15|android16|android17] [make targets...]
#
# Without arguments, builds the default ruan config
# (gki_defconfig + parrot + ruan + debugfs), matching the stock ROM.
#
# With a device and Android version argument, sources
# build.config.<device>.android<NN> and builds a GKI-compliant kernel for
# that Android release, suitable for both HyperOS and AOSP vendor ramdisks.
# The same kernel binary works with HyperOS, AOSP, OneUI 8+, ColorOS and
# any other Android-based ROM, since they all use the same Android kernel
# interfaces.
#
# Build requirements:
#   - AOSP clang (tested with clang-r416183b, the compiler of the GKI builds).
#     Another compiler changes symbol CRCs and stock vendor modules will
#     no longer load. Set CLANG_DIR or pass the clang directory as the first
#     argument.
#   - aarch64-linux-gnu- cross toolchain (CROSS_COMPILE)
#   - GNU make
#
#   ./build.sh ruan android14                           # Android 14 / GKI 2.0
#   ./build.sh dizi android15 Image                     # Android 15 / GKI 3.0, build Image only
#   ./build.sh ruan android16 modules dtbs              # Android 16 / GKI 3.1
#   ./build.sh dizi android17                           # Android 17 / GKI 4.0
set -euo pipefail

K=$(cd "$(dirname "$0")" && pwd)

# --- Parse arguments -------------------------------------------------------
# First argument may be a clang directory.
CLANG_DIR_ARG=""
REMAINING_ARGS=()
for arg in "$@"; do
    if [ -z "$CLANG_DIR_ARG" ] && [ -d "$arg" ] && [ -x "$arg/bin/clang" ]; then
        CLANG_DIR_ARG="$arg"
    else
        REMAINING_ARGS+=("$arg")
    fi
done

# --- Clang setup -----------------------------------------------------------
# Prefer CLANG_DIR env var, then the directory argument, then a default
# location next to the kernel tree.
CLANG_DIR="${CLANG_DIR:-${CLANG_DIR_ARG:-}}"
if [ -z "$CLANG_DIR" ]; then
    # Try common locations
    for candidate in \
        "$K/../clang-r416183b" \
        "$K/../clang-r563880c" \
        "$K/prebuilts/clang/kernel/linux-x86/clang-r416183b"; do
        if [ -d "$candidate" ] && [ -x "$candidate/bin/clang" ]; then
            CLANG_DIR="$candidate"
            break
        fi
    done
fi

if [ -z "$CLANG_DIR" ] || [ ! -x "$CLANG_DIR/bin/clang" ]; then
    echo "error: AOSP clang not found." >&2
    echo "       Set CLANG_DIR to a directory containing bin/clang" >&2
    echo "       (e.g. CLANG_DIR=/path/to/clang-r416183b)" >&2
    echo "       Stock vendor modules require clang-r416183b for KMI compatibility." >&2
    exit 1
fi

# Verify clang version (requires r416183b for KMI compatibility)
CLANG_VERSION=$("$CLANG_DIR/bin/clang" --version 2>/dev/null | head -1)
echo "Using clang: $CLANG_VERSION"
echo "Clang dir:   $CLANG_DIR"

export PATH="$CLANG_DIR/bin:$PATH"
export CROSS_COMPILE=aarch64-linux-gnu-
export CROSS_COMPILE_ARM32=arm-linux-gnueabi-
export HOSTCFLAGS="-I/usr/include/openssl-3"
export HOSTLDFLAGS="-L/usr/lib/openssl-3 -Wl,-rpath,/usr/lib/openssl-3"

# Boot image parameters (must match the stock ROM for KMI/compatibility)
export BOOT_IMAGE_HEADER_VERSION=3
export BASE_ADDRESS=0x80000000
export PAGE_SIZE=4096

# --- Device and Android version --------------------------------------------
DEVICE=""
ANDROID_VER=""
TARGETS=()

for arg in "${REMAINING_ARGS[@]}"; do
    case "$arg" in
        ruan|dizi)
            DEVICE="$arg"
            ;;
        android14|android15|android16|android17)
            ANDROID_VER="$arg"
            ;;
        *)
            TARGETS+=("$arg")
            ;;
    esac
done

# Default device is ruan.
[ -n "$DEVICE" ] || DEVICE=ruan
O=${O:-$K/out-${DEVICE}66}
[ -n "$ANDROID_VER" ] && O="${O}.${ANDROID_VER}"

M="make -C $K O=$O ARCH=arm64 LLVM=1 LLVM_IAS=1 \
    CROSS_COMPILE=$CROSS_COMPILE \
    CROSS_COMPILE_ARM32=$CROSS_COMPILE_ARM32 \
    HOSTCFLAGS=$HOSTCFLAGS HOSTLDFLAGS=$HOSTLDFLAGS"

echo "Device:      $DEVICE"
echo "Output dir:  $O"

if [ -n "$ANDROID_VER" ]; then
    BC="$K/build.config.${DEVICE}.${ANDROID_VER}"
    if [ ! -f "$BC" ]; then
        echo "error: build config not found: $BC" >&2
        exit 1
    fi
    # shellcheck source=/dev/null
    . "$BC"
    echo "Android:     $ANDROID_VER (GKI $GKI_VERSION)"
    echo "Configs:     $CONFIG_FILES"
    # shellcheck disable=SC2086
    $M $CONFIG_FILES
else
    echo "Android:     stock ROM config"
    if [ "$DEVICE" = "dizi" ]; then
        $M gki_defconfig vendor/parrot_GKI.config vendor/dizi_GKI.config vendor/debugfs.config
    else
        $M gki_defconfig vendor/parrot_GKI.config vendor/ruan_GKI.config vendor/debugfs.config
    fi
fi

if [ ${#TARGETS[@]} -gt 0 ]; then
    set -- "${TARGETS[@]}"
else
    set -- Image modules dtbs
fi
echo "Targets:     $*"
$M -j"$(nproc)" "$@"
