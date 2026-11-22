### AnyKernel3 Ramdisk Mod Script
## Clyra-Flip Kernel for Xiaomi ruan/dizi (SM7435)

### AnyKernel setup
# global properties
properties() {
kernel.string=Clyra-Flip Kernel 6.6.144 for ruan/dizi
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
} # end properties

### AnyKernel install
# boot files attributes
boot_attributes() {
set_perm_recursive 0 0 755 644 $RAMDISK/*;
set_perm_recursive 0 0 750 750 $RAMDISK/init* $RAMDISK/sbin;
} # end attributes

# boot shell variables
BLOCK=auto;
IS_SLOT_DEVICE=1;
RAMDISK_COMPRESSION=auto;
PATCH_VBMETA_FLAG=auto;

# import functions/variables and setup patching - see for reference (DO NOT REMOVE)
. tools/ak3-core.sh;

# boot install
dump_boot;

# Replace kernel Image with Clyra-Flip build
# AnyKernel3 automatically detects Image, Image.gz-dtb, zImage, etc. in zip root
# and uses it as the new kernel when repacking boot.img

write_boot;
## end boot install


## vendor_boot files attributes
vendor_boot_attributes() {
set_perm_recursive 0 0 755 644 $RAMDISK/*;
set_perm_recursive 0 0 750 750 $RAMDISK/init* $RAMDISK/sbin;
} # end attributes

# vendor_boot shell variables
BLOCK=vendor_boot;
IS_SLOT_DEVICE=1;
RAMDISK_COMPRESSION=auto;
PATCH_VBMETA_FLAG=auto;

# reset for vendor_boot patching
reset_ak;

# vendor_boot install
# For ruan/dizi, vendor_boot contains the DTB and modules.
# Use split_boot to skip ramdisk unpack (vendor_boot v3 format on SM7435).
split_boot;

# Replace DTB if included in zip root (dtb.img or dtb/)
# AnyKernel3 will use dtb from zip root if present

write_boot;
## end vendor_boot install
