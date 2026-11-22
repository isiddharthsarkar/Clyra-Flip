#!/bin/bash
# ruan 6.6 kernel build.
#
# Usage: build.sh [android14|android15|android16] [make targets...]
#
# Without an Android version argument, builds the default ruan config
# (gki_defconfig + parrot + ruan + debugfs), matching the stock ROM.
#
# With an Android version argument, sources build.config.ruan.android<NN>
# and builds a GKI-compliant kernel for that Android release, suitable for
# both HyperOS and AOSP vendor ramdisks.
#
# Examples:
#   ./build.sh                      # default ruan (stock ROM config)
#   ./build.sh android14            # Android 14 / GKI 2.0
#   ./build.sh android15 Image      # Android 15 / GKI 3.0, build Image only
#   ./build.sh android16 modules dtbs   # Android 16 / GKI 3.1
set -e

K=$(cd "$(dirname "$0")" && pwd)
O=${O:-$K/../out-ruan66}
export PATH=$K/../clang-r563880c/bin:$PATH
export HOSTCFLAGS="-I/usr/include/openssl-3" HOSTLDFLAGS="-L/usr/lib/openssl-3 -Wl,-rpath,/usr/lib/openssl-3"
M="make -C $K O=$O ARCH=arm64 LLVM=1 LLVM_IAS=1 HOSTCFLAGS=$HOSTCFLAGS HOSTLDFLAGS=$HOSTLDFLAGS"

ANDROID_VER=""
TARGETS=()

for arg in "$@"; do
    case "$arg" in
        android14|android15|android16)
            ANDROID_VER="$arg"
            ;;
        *)
            TARGETS+=("$arg")
            ;;
    esac
done

if [ -n "$ANDROID_VER" ]; then
    BC="$K/build.config.ruan.$ANDROID_VER"
    if [ ! -f "$BC" ]; then
        echo "error: build config not found: $BC" >&2
        exit 1
    fi
    # shellcheck source=/dev/null
    . "$BC"
    echo "Building Clyra-Flip for $ANDROID_VER (GKI $GKI_VERSION, Android $COMMON_ANDROID_VERSION)"
    echo "Configs: $CONFIG_FILES"
    # shellcheck disable=SC2086
    $M $CONFIG_FILES
else
    echo "Building Clyra-Flip default ruan config (stock ROM)"
    $M gki_defconfig vendor/parrot_GKI.config vendor/ruan_GKI.config vendor/debugfs.config
fi

if [ ${#TARGETS[@]} -gt 0 ]; then
    set -- "${TARGETS[@]}"
else
    set -- Image modules dtbs
fi
$M -j$(nproc) "$@"
