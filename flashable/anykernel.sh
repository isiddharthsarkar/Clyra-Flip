### AnyKernel3 Ramdisk Mod Script
## Clyra-Flip Kernel 6.6.162-Clyra-Flip — Universal for Xiaomi ruan & dizi (SM7435)
## Auto-detects device AND Android version — flash and reboot, no choices needed.

### AnyKernel setup
# global properties
properties() { '
kernel.string=Clyra-Flip Kernel 6.6.162-Clyra-Flip — Universal ruan/dizi, Android 14-17
do.devicecheck=1
do.modules=0
do.systemless=1
do.cleanup=1
do.cleanuponabort=0
device.name1=ruan
device.name2=dizi
supported.versions=
supported.patchlevels=
supported.vendorpatchlevels=
'; } # end properties


### AnyKernel install

# --- Detect device ---------------------------------------------------------
# Try several sources so the zip works in TWRP, OrangeFox, and stock recovery.
DEVICE=$(getprop ro.product.device 2>/dev/null)
[ -z "$DEVICE" ] && DEVICE=$(getprop ro.build.product 2>/dev/null)
[ -z "$DEVICE" ] && DEVICE=$(getprop ro.product.name 2>/dev/null)
[ -z "$DEVICE" ] && DEVICE=$(cat /proc/device-tree/model 2>/dev/null | tr -d '\0')
[ -z "$DEVICE" ] && DEVICE=$(cat /proc/device-tree/compatible 2>/dev/null | tr '\0' ' ')

case "$DEVICE" in
  *ruan*|*2405CPCFAG*)  DEVICE="ruan" ;;
  *dizi*|*POCO*Pad*|*2405CPCFBG*) DEVICE="dizi" ;;
  *)       abort "Unsupported device: $DEVICE. Aborting..." ;;
esac

ui_print " "
ui_print "Device detected: $DEVICE"
ui_print " "

# --- Detect Android version -----------------------------------------------
# Check mounted ROM partitions first, then recovery getprop.
ANDROID_VER=""
for prop in /system/build.prop /system_root/system/build.prop /system/system/build.prop /vendor/build.prop; do
  if [ -f "$prop" ]; then
    rom_ver=$(grep -m1 '^ro\.build\.version\.release=' "$prop" 2>/dev/null | cut -d= -f2 | tr -d ' \r\n')
    [ -n "$rom_ver" ] && { ANDROID_VER="$rom_ver"; break; }
  fi
done

[ -z "$ANDROID_VER" ] && ANDROID_VER=$(getprop ro.build.version.release 2>/dev/null)
[ -z "$ANDROID_VER" ] && ANDROID_VER=$(getprop ro.build.version.sdk 2>/dev/null)

case "$ANDROID_VER" in
  14|34) ANDROID_VER="android14" ;;
  15|35) ANDROID_VER="android15" ;;
  16|36) ANDROID_VER="android16" ;;
  17|37) ANDROID_VER="android17" ;;
  *)
    ui_print "Unrecognized Android release ($ANDROID_VER), defaulting to android14 (stock baseline)"
    ANDROID_VER="android14"
    ;;
esac

ui_print "Target Android release: $ANDROID_VER"
ui_print " "

# --- Select the correct kernel Image for device + Android ------------------
KERNEL_IMG="Image.${DEVICE}.${ANDROID_VER}"
if [ -f "$KERNEL_IMG" ]; then
  cp "$KERNEL_IMG" "Image"
  ui_print "Using kernel: $KERNEL_IMG"
elif [ -f "Image.${DEVICE}.android14" ]; then
  cp "Image.${DEVICE}.android14" "Image"
  ui_print "Using fallback kernel: Image.${DEVICE}.android14"
elif [ -f "Image" ]; then
  ui_print "Using bundled Image"
else
  abort "Kernel Image for $DEVICE not found in zip. Aborting..."
fi

# --- Optional DTB for this device ------------------------------------------
if [ -f "dtb/${DEVICE}.dtb" ]; then
  cp "dtb/${DEVICE}.dtb" "dtb"
  ui_print "Using DTB: dtb/${DEVICE}.dtb"
else
  ui_print "Keeping stock ROM DTB"
fi

ui_print " "

# --- Determine active boot slot ------------------------------------------
# ruan/dizi boot with header v4: the bootloader passes androidboot.slot_suffix
# in /proc/bootconfig. getprop in recovery only reads build.prop files.
slot=$(getprop ro.boot.slot_suffix 2>/dev/null);
[ "$slot" ] || slot=$(sed -n 's/^androidboot\.slot_suffix = "\(.*\)"$/\1/p' /proc/bootconfig 2>/dev/null);
[ "$slot" ] || slot=$(grep -o 'androidboot.slot_suffix=[^ ]*' /proc/cmdline | cut -d= -f2);
case $slot in
  _a|_b) ;;
  a|b)   slot="_$slot" ;;
  *)     abort "Unable to determine the active slot. Aborting...";;
esac;
for byname in /dev/block/bootdevice/by-name /dev/block/by-name; do
  [ -e $byname/boot$slot ] && break;
done;
[ -e $byname/boot$slot ] || abort "boot$slot not found. Aborting...";
ui_print "Installing to boot$slot";

# boot shell variables
BLOCK=$byname/boot$slot;
IS_SLOT_DEVICE=0;
RAMDISK_COMPRESSION=auto;
PATCH_VBMETA_FLAG=auto;

# import functions/variables and setup patching - see for reference (DO NOT REMOVE)
. tools/ak3-core.sh;

# GKI: only the kernel in boot is replaced. The vendor modules, dtb and
# ramdisks of the ROM stay as they are.
split_boot;
flash_boot;
## end boot install


## vendor_boot files attributes
vendor_boot_attributes() {
set_perm_recursive 0 0 755 644 $RAMDISK/*;
set_perm_recursive 0 0 750 750 $RAMDISK/init* $RAMDISK/sbin;
} # end attributes

# vendor_boot install (only if custom DTB provided in zip)
if [ -f "dtb" ] && [ -e "$byname/vendor_boot$slot" ]; then
  BLOCK=$byname/vendor_boot$slot;
  IS_SLOT_DEVICE=0;
  RAMDISK_COMPRESSION=auto;
  PATCH_VBMETA_FLAG=auto;

  reset_ak;
  split_boot;
  write_boot;
fi
## end vendor_boot install

ui_print " "
ui_print "Clyra-Flip Kernel installed for $DEVICE on $ANDROID_VER!"
ui_print "Reboot to system."