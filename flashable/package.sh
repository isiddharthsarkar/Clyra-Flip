#!/bin/bash
# Clyra-Flip AnyKernel3 flashable zip packager for TWRP / OrangeFox
# UNIVERSAL build: packages ruan + dizi kernels for ALL Android versions
# (14, 15, 16, 17) into ONE zip. Auto-detects device + Android at flash time.
#
# Usage: ./package.sh <build-root>
#
#   <build-root>   Directory containing out-ruan66 and out-dizi66 subdirs
#                  (or individual out-<device>66.android<NN> dirs)
#
# Creates a universal flashable zip:
#   clyra-flip-kernel-universal-<release>.zip
#
# The zip contains Image.<device>.android<NN> for all 8 combinations
# (ruan/dizi × android14/15/16/17) plus both DTBs.
# anykernel.sh auto-detects device and Android version at flash time.
# No mkbootimg is required on the build machine.
#
# Build requirement: all 8 kernel builds must be done first with ./build.sh
#
# Example:
#   ./build.sh <clang-dir> ruan android14   # produces out-ruan66.android14
#   ./build.sh <clang-dir> ruan android15   # produces out-ruan66.android15
#   ... (all 8 combos)
#   ./package.sh .

set -euo pipefail

BUILD_ROOT="${1:-.}"

K=$(cd "$(dirname "$0")/.." && pwd)
FLASHABLE="$K/flashable"
ZIP_DIR="$K/flashable-zip"

# Detect kernel release from first available build dir
REL="6.6.162-Clyra-Flip"
for d in "$BUILD_ROOT"/out-ruan66* "$BUILD_ROOT"/out-dizi66*; do
  if [ -f "$d/include/config/kernel.release" ]; then
    REL=$(cat "$d/include/config/kernel.release")
    break
  fi
done

# Devices and Android versions to package
DEVICES="ruan dizi"
ANDROID_VERS="android14 android15 android16 android17"

echo "=== Clyra-Flip AnyKernel3 Universal Flashable Zip Packager ==="
echo "Build root:  $BUILD_ROOT"
echo "Kernel rel:  $REL"
echo ""

# Clean and prepare staging directory
rm -rf "$ZIP_DIR"
mkdir -p "$ZIP_DIR"

# Copy the entire flashable structure (minus README.md)
cp -a "$FLASHABLE/." "$ZIP_DIR/"

# Remove README from the zip (don't ship it)
rm -f "$ZIP_DIR/README.md"

# Collect all kernel Images and DTBs
TOTAL_IMAGES=0
DTB_COUNT=0

for DEVICE in $DEVICES; do
  for ANDROID_VER in $ANDROID_VERS; do
    # Check if pre-named Image already exists in BUILD_ROOT
    if [ -f "$BUILD_ROOT/Image.${DEVICE}.${ANDROID_VER}" ]; then
      cp "$BUILD_ROOT/Image.${DEVICE}.${ANDROID_VER}" "$ZIP_DIR/Image.${DEVICE}.${ANDROID_VER}"
      TOTAL_IMAGES=$((TOTAL_IMAGES + 1))
      echo "Image copied:  Image.${DEVICE}.${ANDROID_VER}"
      continue
    fi

    # Find the build output directory for this device+android combo
    OUT_DIR=""
    for candidate in \
      "$BUILD_ROOT/out-${DEVICE}66.${ANDROID_VER}" \
      "$BUILD_ROOT/downloaded-artifacts/build-${DEVICE}-${ANDROID_VER}/out-${DEVICE}66.${ANDROID_VER}" \
      "$BUILD_ROOT/artifacts/build-${DEVICE}-${ANDROID_VER}/out-${DEVICE}66.${ANDROID_VER}" \
      "$BUILD_ROOT/out-${DEVICE}66" \
      "$BUILD_ROOT/${DEVICE}_${ANDROID_VER}" \
      "$BUILD_ROOT/out-${DEVICE}-${ANDROID_VER}"; do
      if [ -d "$candidate" ]; then
        OUT_DIR="$candidate"
        break
      fi
    done

    if [ -z "$OUT_DIR" ]; then
      echo "WARNING: no build dir found for $DEVICE $ANDROID_VER, skipping"
      continue
    fi

    # Find the kernel Image
    KERNEL_IMG=""
    for cand in "arch/arm64/boot/Image" "arch/arm64/boot/Image.gz-dtb" "arch/arm64/boot/Image-dtb"; do
      if [ -f "$OUT_DIR/$cand" ]; then
        KERNEL_IMG="$OUT_DIR/$cand"
        break
      fi
    done

    if [ -z "$KERNEL_IMG" ] || [ ! -f "$KERNEL_IMG" ]; then
      echo "WARNING: kernel Image not found for $DEVICE $ANDROID_VER in $OUT_DIR, skipping"
      continue
    fi

    # Copy as Image.<device>.android<NN>
    cp "$KERNEL_IMG" "$ZIP_DIR/Image.${DEVICE}.${ANDROID_VER}"
    TOTAL_IMAGES=$((TOTAL_IMAGES + 1))
    echo "Image copied:  Image.${DEVICE}.${ANDROID_VER}"

    # Copy DTBs from this build
    DTB_DIR="$OUT_DIR/arch/arm64/boot/dts/vendor/qcom"
    if [ -d "$DTB_DIR" ]; then
      mkdir -p "$ZIP_DIR/dtb"
      for dtb in "$DTB_DIR"/*.dtb; do
        if [ -f "$dtb" ]; then
          dtb_name=$(basename "$dtb")
          # Only copy if not already present (DTB may be same across Android versions)
          if [ ! -f "$ZIP_DIR/dtb/$dtb_name" ]; then
            cp "$dtb" "$ZIP_DIR/dtb/$dtb_name"
            DTB_COUNT=$((DTB_COUNT + 1))
            echo "DTB copied:      $dtb_name"
          fi
        fi
      done
    fi
  done
done

if [ "$TOTAL_IMAGES" -eq 0 ]; then
  echo ""
  echo "ERROR: No kernel images found! Build all combinations first:"
  echo "  for dev in ruan dizi; do"
  echo "    for ver in android14 android15 android16 android17; do"
  echo "      ./build.sh <clang-dir> \$dev \$ver"
  echo "    done"
  echo "  done"
  exit 1
fi

echo ""
echo "Images packaged: $TOTAL_IMAGES"
echo "DTBs packaged:   $DTB_COUNT"

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
echo "  Image.<device>.android<NN>  — kernel for each device+Android combo"
echo "  dtb/*.dtb                   — device tree blobs"
echo "  anykernel.sh                — auto-detecting installer"
echo ""
echo "To flash via TWRP / OrangeFox:"
echo "  1. Copy $ZIP_PATH to your device"
echo "  2. Reboot to recovery"
echo "  3. Install -> select the zip -> swipe to flash"
echo "  4. Reboot to system"
echo ""
echo "anykernel.sh auto-detects your device (ruan/dizi)"
echo "and Android version (14/15/16/17) automatically."
echo "No choices needed — just flash and reboot."
echo ""
echo "The zip uses AnyKernel3 to patch boot.img at flash time."
echo "No additional tools needed on the build machine."
