#!/bin/bash
# ruan/dizi 6.6 kernel build.
#
# Usage: build.sh [ruan|dizi] [android14|android15|android16|android17] [make targets...]
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
# Examples:
#   ./build.sh                          # default ruan (stock ROM config)
#   ./build.sh dizi                     # default dizi (stock ROM config, WiFi)
#   ./build.sh ruan android14           # Android 14 / GKI 2.0
#   ./build.sh dizi android15 Image     # Android 15 / GKI 3.0, build Image only
#   ./build.sh ruan android16 modules dtbs   # Android 16 / GKI 3.1
#   ./build.sh dizi android17           # Android 17 / GKI 4.0
set -e

K=$(cd "$(dirname "$0")" && pwd)
O=${O:-$K/../out-${DEVICE:-ruan}66}
export PATH=$K/../clang-r563880c/bin:$PATH
export HOSTCFLAGS="-I/usr/include/openssl-3" HOSTLDFLAGS="-L/usr/lib/openssl-3 -Wl,-rpath,/usr/lib/openssl-3"
M="make -C $K O=$O ARCH=arm64 LLVM=1 LLVM_IAS=1 HOSTCFLAGS=$HOSTCFLAGS HOSTLDFLAGS=$HOSTLDFLAGS"

DEVICE=""
ANDROID_VER=""
TARGETS=()

for arg in "$@"; do
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
O=${O:-$K/../out-${DEVICE}66}

if [ -n "$ANDROID_VER" ]; then
    BC="$K/build.config.${DEVICE}.${ANDROID_VER}"
    if [ ! -f "$BC" ]; then
        echo "error: build config not found: $BC" >&2
        exit 1
    fi
    # shellcheck source=/dev/null
    . "$BC"
    echo "Building Clyra-Flip for $DEVICE $ANDROID_VER (GKI $GKI_VERSION, Android $COMMON_ANDROID_VERSION)"
    echo "Configs: $CONFIG_FILES"
    # shellcheck disable=SC2086
    $M $CONFIG_FILES
else
    echo "Building Clyra-Flip default $DEVICE config (stock ROM)"
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
$M -j$(nproc) "$@"
