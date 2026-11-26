#!/bin/bash
# Clyra-Flip AnyKernel3 flashable zip packager for TWRP / OrangeFox
# Packages ruan and/or dizi kernels for Android versions (14, 15, 16, 17) into a zip.
# Auto-detects device + Android version at flash time.
#
# Usage: ./package.sh [build-root]
#
#   [build-root]   Directory containing out-ruan66 and out-dizi66 subdirs
#                  (or individual out-<device>66.android<NN> dirs, default: .)
#
# Creates a flashable zip:
#   clyra-flip-kernel-<tag>-<release>-<timestamp>.zip
#
# The zip contains Image.<device>.android<NN> for packaged builds plus DTBs.
# anykernel.sh auto-detects device and Android version at flash time.

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

MISSING=0

echo "=== Clyra-Flip AnyKernel3 Flashable Zip Packager ==="
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
      echo "ERROR: no build dir found for $DEVICE $ANDROID_VER"
      MISSING=1
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
      echo "ERROR: no kernel image found for $DEVICE $ANDROID_VER"
      MISSING=1
      continue
    fi

    # Copy as Image.<device>.android<NN>
    cp "$KERNEL_IMG" "$ZIP_DIR/Image.${DEVICE}.${ANDROID_VER}"
    if [ ! -f "$ZIP_DIR/Image" ]; then
      cp "$KERNEL_IMG" "$ZIP_DIR/Image"
    fi
    TOTAL_IMAGES=$((TOTAL_IMAGES + 1))
    echo "Image copied:  Image.${DEVICE}.${ANDROID_VER}"

    # Harvest compiled loadable modules (.ko) if present
    if [ -d "$OUT_DIR" ]; then
      MODULES_DIR="$ZIP_DIR/modules/vendor/lib/modules"
      mkdir -p "$MODULES_DIR"
      find "$OUT_DIR" -name "*.ko" -exec cp -f {} "$MODULES_DIR/" \; 2>/dev/null || true
    fi

    # Copy DTBs from this build
    DTB_DIR="$OUT_DIR/arch/arm64/boot/dts/vendor/qcom"
    if [ -d "$DTB_DIR" ]; then
      mkdir -p "$ZIP_DIR/dtb"
      for dtb in "$DTB_DIR"/*.dtb; do
        if [ -f "$dtb" ]; then
          dtb_name=$(basename "$dtb")
          # Include Android version in filename to avoid overwriting
          # different DTBs from different Android versions
          cp "$dtb" "$ZIP_DIR/dtb/${dtb_name%.dtb}.${ANDROID_VER}.dtb"
          DTB_COUNT=$((DTB_COUNT + 1))
          echo "DTB copied:      ${dtb_name%.dtb}.${ANDROID_VER}.dtb"
        fi
      done
    fi
  done
done

if [ "$MISSING" -eq 1 ]; then
  echo ""
  echo "ERROR: Some build directories or kernel images are missing. Build all combinations first:"
  echo "  for dev in ruan dizi; do"
  echo "    for ver in android14 android15 android16 android17; do"
  echo "      ./build.sh <clang-dir> \$dev \$ver"
  echo "    done"
  echo "  done"
  exit 1
fi

if [ "$TOTAL_IMAGES" -eq 0 ]; then
  echo ""
  echo "ERROR: No kernel images found in $BUILD_ROOT!"
  echo "Build kernel first:"
  echo "  ./build.sh <clang-dir> <device> <android-version>"
  exit 1
fi

echo ""
echo "Images packaged: $TOTAL_IMAGES"
echo "DTBs packaged:   $DTB_COUNT"

# Clean up empty module or placeholder directories
rm -f "$ZIP_DIR/ramdisk/placeholder" "$ZIP_DIR/patch/placeholder" "$ZIP_DIR/modules/system/lib/modules/placeholder"
rmdir "$ZIP_DIR/ramdisk" "$ZIP_DIR/patch" "$ZIP_DIR/modules/system/lib/modules" 2>/dev/null || true
if [ -d "$ZIP_DIR/modules/vendor/lib/modules" ]; then
  MODULE_COUNT=$(find "$ZIP_DIR/modules/vendor/lib/modules" -name "*.ko" 2>/dev/null | wc -l)
  if [ "$MODULE_COUNT" -gt 0 ]; then
    echo "Modules packaged: $MODULE_COUNT"
  else
    rm -rf "$ZIP_DIR/modules"
  fi
fi

# Determine package tag
TAG="universal"
if [ "$TOTAL_IMAGES" -eq 1 ]; then
  for dev in $DEVICES; do
    for ver in $ANDROID_VERS; do
      if [ -f "$ZIP_DIR/Image.${dev}.${ver}" ]; then
        TAG="${dev}-${ver}"
        break 2
      fi
    done
  done
fi

TIMESTAMP=$(date +%Y%m%d-%H%M)
ZIP_NAME="clyra-flip-kernel-${TAG}-$(echo "$REL" | tr '/' '-')-${TIMESTAMP}.zip"
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
echo "Contents:"
echo "  Image.<device>.android<NN>  - kernel for each device+Android combo"
echo "  dtb/*.dtb                   - device tree blobs (if present)"
echo "  modules/vendor/lib/modules/ - loadable kernel modules (if present)"
echo "  anykernel.sh                - auto-detecting installer"
echo ""
echo "To flash via TWRP / OrangeFox:"
echo "  1. Copy $ZIP_PATH to your device"
echo "  2. Reboot to recovery"
echo "  3. Install -> select the zip -> swipe to flash"
echo "  4. Reboot to system"
