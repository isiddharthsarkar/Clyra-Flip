#!/bin/bash
# Clyra-Flip AnyKernel3 flashable zip packager for TWRP / OrangeFox
#
# Usage: ./package.sh <kernel-out-dir>
#
#   <kernel-out-dir>   Directory with kernel build output (e.g. out-ruan66)
#
# Copies the kernel Image and DTBs into the AnyKernel3 zip structure and
# creates a flashable zip:
#   clyra-flip-kernel-<device>-<release>.zip
#
# The zip uses AnyKernel3 (split_boot + flash_boot) to patch the device's
# boot image at flash time, preserving the original ramdisk and supporting
# Magisk retention. No mkbootimg is required on the build machine.
#
# Build requirement: the kernel must be built first with ./build.sh
#
# Example:
#   ./package.sh out-ruan66
#   ./package.sh out-dizi66

set -euo pipefail

if [ $# -lt 1 ]; then
    echo "Usage: $0 <kernel-out-dir>" >&2
    exit 1
fi

OUT_DIR="$1"

K=$(cd "$(dirname "$0")/.." && pwd)
FLASHABLE="$K/flashable"
ZIP_DIR="$K/flashable-zip"

# Detect device from output directory name
case "$OUT_DIR" in
    *dizi*) DEVICE="dizi" ;;
    *ruan*) DEVICE="ruan" ;;
    *)      DEVICE="ruan" ;;
esac

# Detect kernel release
if [ -f "$OUT_DIR/include/config/kernel.release" ]; then
    REL=$(cat "$OUT_DIR/include/config/kernel.release")
else
    REL="6.6.144-Clyra-Flip"
fi

# Find the kernel Image
KERNEL_IMG=""
for candidate in "arch/arm64/boot/Image" "arch/arm64/boot/Image.gz-dtb" "arch/arm64/boot/Image-dtb"; do
    if [ -f "$OUT_DIR/$candidate" ]; then
        KERNEL_IMG="$OUT_DIR/$candidate"
        break
    fi
done

if [ -z "$KERNEL_IMG" ] || [ ! -f "$KERNEL_IMG" ]; then
    echo "error: kernel Image not found in $OUT_DIR" >&2
    echo "       Build the kernel first: ./build.sh $DEVICE" >&2
    exit 1
fi

echo "=== Clyra-Flip AnyKernel3 Flashable Zip Packager ==="
echo "Device:      $DEVICE"
echo "Kernel rel:  $REL"
echo "Kernel img:  $KERNEL_IMG"
echo ""

# Clean and prepare staging directory
rm -rf "$ZIP_DIR"
mkdir -p "$ZIP_DIR"

# Copy the entire flashable structure (minus README.md)
cp -a "$FLASHABLE/." "$ZIP_DIR/"

# Remove README from the zip (don't ship it)
rm -f "$ZIP_DIR/README.md"

# Copy kernel Image to zip root
cp "$KERNEL_IMG" "$ZIP_DIR/Image"

# Copy DTBs to zip root/dtb/ if they exist
DTB_DIR="$OUT_DIR/arch/arm64/boot/dts/vendor/qcom"
if [ -d "$DTB_DIR" ]; then
    mkdir -p "$ZIP_DIR/dtb"
    dtb_count=0
    for dtb in "$DTB_DIR"/*.dtb; do
        if [ -f "$dtb" ]; then
            cp "$dtb" "$ZIP_DIR/dtb/"
            dtb_count=$((dtb_count + 1))
        fi
    done
    echo "DTBs copied:   $dtb_count"
fi

# Remove placeholder files from template
rm -f "$ZIP_DIR/ramdisk/placeholder" "$ZIP_DIR/patch/placeholder" "$ZIP_DIR/modules/system/lib/modules/placeholder"
rmdir "$ZIP_DIR/ramdisk" "$ZIP_DIR/patch" "$ZIP_DIR/modules/system/lib/modules" 2>/dev/null || true

# Package the zip
ZIP_NAME="clyra-flip-kernel-${DEVICE}-$(echo "$REL" | tr '/' '-').zip"
ZIP_PATH="$K/$ZIP_NAME"

cd "$ZIP_DIR"
zip -r9 "$ZIP_PATH" . -x '.git*' 'README.md' '*placeholder'
cd "$K"

# Clean up staging
rm -rf "$ZIP_DIR"

echo ""
echo "========================================"
echo "Flashable zip created: $ZIP_PATH"
echo "========================================"
echo ""
echo "To flash via TWRP / OrangeFox:"
echo "  1. Copy $ZIP_PATH to your device"
echo "  2. Reboot to recovery"
echo "  3. Install -> select the zip -> swipe to flash"
echo "  4. Reboot to system"
echo ""
echo "The zip uses AnyKernel3 to patch boot.img at flash time."
echo "No additional tools needed on the build machine."
