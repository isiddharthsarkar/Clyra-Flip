#!/bin/bash
# Clyra-Flip AnyKernel3 flashable zip packager for TWRP / OrangeFox
# UNIVERSAL build: packages both ruan and dizi kernels into one zip.
#
# Usage: ./package.sh <ruan-out-dir> <dizi-out-dir>
#
#   <ruan-out-dir>   Directory with ruan kernel build output (e.g. out-ruan66)
#   <dizi-out-dir>   Directory with dizi kernel build output (e.g. out-dizi66)
#
# Creates a universal flashable zip:
#   clyra-flip-kernel-universal-<release>.zip
#
# The zip contains both Image.ruan and Image.dizi plus both DTBs.
# anykernel.sh auto-detects the device at flash time and installs the
# correct kernel. No mkbootimg is required on the build machine.
#
# Build requirement: both kernels must be built first with ./build.sh
#
# Example:
#   ./package.sh out-ruan66 out-dizi66

set -euo pipefail

if [ $# -lt 2 ]; then
    echo "Usage: $0 <ruan-out-dir> <dizi-out-dir>" >&2
    echo "" >&2
    echo "  Build both kernels first:" >&2
    echo "    ./build.sh <clang-dir> ruan android16" >&2
    echo "    ./build.sh <clang-dir> dizi android16" >&2
    echo "  Then package:" >&2
    echo "    ./package.sh out-ruan66 out-dizi66" >&2
    exit 1
fi

RUAN_OUT="$1"
DIZI_OUT="$2"

K=$(cd "$(dirname "$0")/.." && pwd)
FLASHABLE="$K/flashable"
ZIP_DIR="$K/flashable-zip"

# Detect kernel release from ruan build (both should match)
if [ -f "$RUAN_OUT/include/config/kernel.release" ]; then
    REL=$(cat "$RUAN_OUT/include/config/kernel.release")
elif [ -f "$DIZI_OUT/include/config/kernel.release" ]; then
    REL=$(cat "$DIZI_OUT/include/config/kernel.release")
else
    REL="6.6.144-Clyra-Flip"
fi

# Find ruan kernel Image
RUAN_IMG=""
for candidate in "arch/arm64/boot/Image" "arch/arm64/boot/Image.gz-dtb" "arch/arm64/boot/Image-dtb"; do
    if [ -f "$RUAN_OUT/$candidate" ]; then
        RUAN_IMG="$RUAN_OUT/$candidate"
        break
    fi
done

if [ -z "$RUAN_IMG" ] || [ ! -f "$RUAN_IMG" ]; then
    echo "error: ruan kernel Image not found in $RUAN_OUT" >&2
    echo "       Build the kernel first: ./build.sh <clang-dir> ruan android16" >&2
    exit 1
fi

# Find dizi kernel Image
DIZI_IMG=""
for candidate in "arch/arm64/boot/Image" "arch/arm64/boot/Image.gz-dtb" "arch/arm64/boot/Image-dtb"; do
    if [ -f "$DIZI_OUT/$candidate" ]; then
        DIZI_IMG="$DIZI_OUT/$candidate"
        break
    fi
done

if [ -z "$DIZI_IMG" ] || [ ! -f "$DIZI_IMG" ]; then
    echo "error: dizi kernel Image not found in $DIZI_OUT" >&2
    echo "       Build the kernel first: ./build.sh <clang-dir> dizi android16" >&2
    exit 1
fi

echo "=== Clyra-Flip AnyKernel3 Universal Flashable Zip Packager ==="
echo "Ruan out:    $RUAN_OUT"
echo "Ruan img:    $RUAN_IMG"
echo "Dizi out:    $DIZI_OUT"
echo "Dizi img:    $DIZI_IMG"
echo "Kernel rel:  $REL"
echo ""

# Clean and prepare staging directory
rm -rf "$ZIP_DIR"
mkdir -p "$ZIP_DIR"

# Copy the entire flashable structure (minus README.md)
cp -a "$FLASHABLE/." "$ZIP_DIR/"

# Remove README from the zip (don't ship it)
rm -f "$ZIP_DIR/README.md"

# Copy ruan kernel Image as Image.ruan
cp "$RUAN_IMG" "$ZIP_DIR/Image.ruan"

# Copy dizi kernel Image as Image.dizi
cp "$DIZI_IMG" "$ZIP_DIR/Image.dizi"

# Copy DTBs from both builds
DTB_COUNT=0
for OUT_DIR in "$RUAN_OUT" "$DIZI_OUT"; do
    DTB_DIR="$OUT_DIR/arch/arm64/boot/dts/vendor/qcom"
    if [ -d "$DTB_DIR" ]; then
        mkdir -p "$ZIP_DIR/dtb"
        for dtb in "$DTB_DIR"/*.dtb; do
            if [ -f "$dtb" ]; then
                dtb_name=$(basename "$dtb")
                cp "$dtb" "$ZIP_DIR/dtb/$dtb_name"
                DTB_COUNT=$((DTB_COUNT + 1))
                echo "DTB copied:    $dtb_name"
            fi
        done
    fi
done
echo "DTBs copied:   $DTB_COUNT"

# Remove placeholder files from template
rm -f "$ZIP_DIR/ramdisk/placeholder" "$ZIP_DIR/patch/placeholder" "$ZIP_DIR/modules/system/lib/modules/placeholder"
rmdir "$ZIP_DIR/ramdisk" "$ZIP_DIR/patch" "$ZIP_DIR/modules/system/lib/modules" 2>/dev/null || true

# Package the zip
ZIP_NAME="clyra-flip-kernel-universal-$(echo "$REL" | tr '/' '-').zip"
ZIP_PATH="$K/$ZIP_NAME"

cd "$ZIP_DIR"
zip -r9 "$ZIP_PATH" . -x '.git*' 'README.md' '*placeholder'
cd "$K"

# Clean up staging
rm -rf "$ZIP_DIR"

echo ""
echo "========================================"
echo "Universal flashable zip created: $ZIP_PATH"
echo "========================================"
echo ""
echo "Contents:"
echo "  Image.ruan   - Kernel for ruan (Redmi Note 12 5G)"
echo "  Image.dizi   - Kernel for dizi (Redmi Note 12 WiFi)"
echo "  dtb/*.dtb    - Device tree blobs for both devices"
echo ""
echo "To flash via TWRP / OrangeFox:"
echo "  1. Copy $ZIP_PATH to your device"
echo "  2. Reboot to recovery"
echo "  3. Install -> select the zip -> swipe to flash"
echo "  4. Reboot to system"
echo ""
echo "anykernel.sh auto-detects your device (ruan or dizi)"
echo "and installs the correct kernel automatically."
echo ""
echo "The zip uses AnyKernel3 to patch boot.img at flash time."
echo "No additional tools needed on the build machine."