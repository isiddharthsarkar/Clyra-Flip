#!/bin/bash
# Clyra-Flip kernel flashable zip packager for TWRP / OrangeFox
#
# Usage: ./package.sh <kernel-out-dir> [vendor_boot.img]
#
#   <kernel-out-dir>   Directory with kernel build output (e.g. out-ruan66)
#   vendor_boot.img    Optional: pre-built vendor_boot.img. If omitted, the
#                      script will try to extract it from the stock ROM or
#                      create a minimal one.
#
# Produces: clyra-flip-kernel-<device>-android<NN>.zip
#
# Required tools: mkbootimg, mkdtboimg, zip
#
# Example:
#   ./package.sh out-ruan66
#   ./package.sh out-dizi66 /path/to/stock/vendor_boot.img

set -euo pipefail

if [ $# -lt 1 ]; then
    echo "Usage: $0 <kernel-out-dir> [vendor_boot.img]" >&2
    exit 1
fi

OUT_DIR="$1"
STOCK_VENDOR_BOOT="${2:-}"

K=$(cd "$(dirname "$0")/.." && pwd)
FLASHABLE="$K/flashable"
ZIP_DIR="$K/flashable-zip"

# Detect device from output directory name
case "$OUT_DIR" in
    *dizi*) DEVICE="dizi" ;;
    *ruan*) DEVICE="ruan" ;;
    *)      DEVICE="ruan" ;;  # default
esac

# Detect Android version from kernel release
if [ -f "$OUT_DIR/include/config/kernel.release" ]; then
    REL=$(cat "$OUT_DIR/include/config/kernel.release")
else
    REL="6.6.144-Clyra-Flip"
fi

# Extract Android version from release string (e.g. 6.6.144-Clyra-Flip -> unknown)
# We tag builds manually via build config; default to generic
ANDROID_VER="unknown"

# Find mkbootimg / mkdtboimg
MKBOOTIMG="${MKBOOTIMG:-mkbootimg}"
MKDTBOIMG="${MKDTBOIMG:-mkdtboimg}"

for tool in "$MKBOOTIMG" "$MKDTBOIMG" zip; do
    if ! command -v "$tool" &>/dev/null; then
        echo "error: required tool '$tool' not found in PATH" >&2
        exit 1
    fi
done

echo "=== Clyra-Flip Flashable Zip Packager ==="
echo "Device:      $DEVICE"
echo "Kernel rel:  $REL"
echo "Out dir:     $OUT_DIR"
echo ""

# Validate build output
if [ ! -f "$OUT_DIR/arch/arm64/boot/Image" ]; then
    echo "error: kernel Image not found in $OUT_DIR/arch/arm64/boot/Image" >&2
    echo "       Build the kernel first: ./build.sh $DEVICE" >&2
    exit 1
fi

# Find the device tree blob (DTB)
DTB_DIR="$OUT_DIR/arch/arm64/boot/dts/vendor/qcom"
DTB_FILE=""
if [ -d "$DTB_DIR" ]; then
    # Prefer ruan/dizi specific dtb, fall back to parrot
    for candidate in "ruan.dtb" "dizi.dtb" "parrot.dtb"; do
        if [ -f "$DTB_DIR/$candidate" ]; then
            DTB_FILE="$DTB_DIR/$candidate"
            break
        fi
    done
    # Fall back to any .dtb in the dir
    if [ -z "$DTB_FILE" ]; then
        DTB_FILE=$(find "$DTB_DIR" -maxdepth 1 -name "*.dtb" | head -1)
    fi
fi

if [ -z "$DTB_FILE" ] || [ ! -f "$DTB_FILE" ]; then
    echo "error: no DTB found in $DTB_DIR" >&2
    exit 1
fi
echo "Using DTB:   $DTB_FILE"

# Clean and prepare staging directory
rm -rf "$ZIP_DIR"
mkdir -p "$ZIP_DIR/META-INF/com/google/android"

# Copy updater-script
cp "$FLASHABLE/META-INF/com/google/android/updater-script" \
   "$ZIP_DIR/META-INF/com/google/android/updater-script"

# --- Build boot.img ---
echo ""
echo "Building boot.img..."
BOOT_IMG="$ZIP_DIR/boot.img"
"$MKBOOTIMG" \
    --kernel "$OUT_DIR/arch/arm64/boot/Image" \
    --dtb "$DTB_FILE" \
    --ramdisk "$OUT_DIR/usr/initramfs_data.cpio.gz" 2>/dev/null \
    --base 0x80000000 \
    --pagesize 4096 \
    --kernel_offset 0x00008000 \
    --ramdisk_offset 0x01000000 \
    --tags_offset 0x00000100 \
    --header_version 1 \
    --os_version 14 \
    --os_patch_level 2024-01 \
    --output "$BOOT_IMG" || {
    echo "warning: mkbootimg with ramdisk failed, trying without ramdisk..."
    "$MKBOOTIMG" \
        --kernel "$OUT_DIR/arch/arm64/boot/Image" \
        --dtb "$DTB_FILE" \
        --base 0x80000000 \
        --pagesize 4096 \
        --kernel_offset 0x00008000 \
        --ramdisk_offset 0x01000000 \
        --tags_offset 0x00000100 \
        --header_version 1 \
        --os_version 14 \
        --os_patch_level 2024-01 \
        --output "$BOOT_IMG"
}
echo "boot.img created: $BOOT_IMG"

# --- Build dtbo.img ---
echo ""
echo "Building dtbo.img..."
DTBO_IMG="$ZIP_DIR/dtbo.img"
# Collect all dtbo files for this device
DTBO_FILES=$(find "$DTB_DIR" -name "*.dtbo" | sort | head -20 || true)
if [ -n "$DTBO_FILES" ]; then
    "$MKDTBOIMG" create "$DTBO_IMG" --page_size=4096 $DTBO_FILES
    echo "dtbo.img created: $DTBO_IMG"
else
    echo "warning: no dtbo files found, creating empty dtbo.img placeholder"
    "$MKDTBOIMG" create "$DTBO_IMG" --page_size=4096 || true
fi

# --- Handle vendor_boot.img ---
echo ""
VENDOR_BOOT_IMG="$ZIP_DIR/vendor_boot.img"
if [ -n "$STOCK_VENDOR_BOOT" ] && [ -f "$STOCK_VENDOR_BOOT" ]; then
    echo "Using provided vendor_boot.img: $STOCK_VENDOR_BOOT"
    cp "$STOCK_VENDOR_BOOT" "$VENDOR_BOOT_IMG"
elif [ -f "$OUT_DIR/vendor_boot.img" ]; then
    echo "Using vendor_boot.img from out dir: $OUT_DIR/vendor_boot.img"
    cp "$OUT_DIR/vendor_boot.img" "$VENDOR_BOOT_IMG"
else
    echo "warning: no vendor_boot.img provided or found."
    echo "         Extract from stock ROM vendor_boot partition, or provide one:"
    echo "         $0 $OUT_DIR /path/to/vendor_boot.img"
    echo "         Creating placeholder (flash will fail on vendor_boot without a real image)..."
    # Create a minimal placeholder - will fail on flash but won't break the zip
    dd if=/dev/zero of="$VENDOR_BOOT_IMG" bs=4096 count=1 2>/dev/null || true
fi

# --- Package the zip ---
echo ""
ZIP_NAME="clyra-flip-kernel-${DEVICE}-$(echo "$REL" | tr '/' '-').zip"
ZIP_PATH="$K/$ZIP_NAME"

cd "$ZIP_DIR"
zip -r "$ZIP_PATH" META-INF boot.img dtbo.img vendor_boot.img
cd "$K"

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
echo "Note: vendor_boot.img must be a real image for the ROM to boot."
echo "      Extract it from your stock ROM if not provided."
