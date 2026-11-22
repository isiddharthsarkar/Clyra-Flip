# Clyra-Flip Flashable Zip (TWRP / OrangeFox) — AnyKernel3

This directory contains an **AnyKernel3**-compatible flashable zip template for
the Clyra-Flip kernel. AnyKernel3 is the industry-standard template for kernel
flashable zips — it patches the device's boot image at flash time using
`magiskboot`, preserving the original ramdisk structure and supporting Magisk
retention.

## Files

| File | Purpose |
|------|---------|
| `anykernel.sh` | Main AnyKernel3 installer — device checks, boot/vendor_boot patching |
| `tools/ak3-core.sh` | AnyKernel3 core functions (dump_boot, write_boot, etc.) |
| `tools/magiskboot` | Boot image patching binary (runs on device in recovery) |
| `tools/busybox` | Busybox for recovery environment |
| `META-INF/com/google/android/update-binary` | Recovery backend binary |
| `META-INF/com/google/android/updater-script` | Edify script (calls update-binary) |
| `ramdisk/` | Ramdisk modifications (optional) |
| `patch/` | Patch files for ramdisk edits (optional) |
| `modules/` | Kernel modules to push (optional) |

## Supported Devices

| Device | Variant | Modem/GNSS |
|--------|---------|------------|
| `ruan` | Redmi Pad Pro 5G / POCO Pad 5G | Yes (5G) |
| `dizi` | Redmi Pad Pro WiFi / POCO Pad WiFi | No (WiFi only) |

Both devices share the same kernel. The zip auto-detects the device via
`ro.product.device`.

## Building the Flashable Zip

### Prerequisites

Build the kernel first:

```sh
# ruan (5G model) — Android 16 / HyperOS 3
./build.sh ruan android16

# dizi (WiFi model) — Android 16 / HyperOS 3
./build.sh dizi android16
```

The kernel build produces:
- `out-<device>66/arch/arm64/boot/Image` — the kernel image
- `out-<device>66/arch/arm64/boot/dts/vendor/qcom/*.dtb` — device tree blobs

### Package the zip

```sh
./flashable/package.sh out-ruan66
```

This copies the kernel `Image` and DTBs into the flashable zip structure and
creates:
```
clyra-flip-kernel-ruan-6.6.144-Clyra-Flip.zip
```

You must provide the built kernel `Image` and DTBs — the package script copies
them into the zip root. AnyKernel3 will then patch the device's boot image at
flash time using `magiskboot`.

### What goes in the zip

```
clyra-flip-kernel-*.zip
├── Image                      ← kernel image (from build output)
├── dtb/                       ← device tree blobs (optional)
│   ├── ruan.dtb
│   └── dizi.dtb
├── anykernel.sh               ← AnyKernel3 installer
├── tools/
│   ├── ak3-core.sh
│   ├── magiskboot
│   └── busybox
├── ramdisk/                   ← ramdisk modifications (optional)
├── patch/                     ← patch files (optional)
├── modules/                   ← kernel modules (optional)
└── META-INF/
    └── com/google/android/
        ├── update-binary
        └── updater-script
```

## Flashing

1. Copy the `.zip` to your device's internal storage or USB-OTG drive.
2. Reboot to TWRP / OrangeFox recovery.
3. **Install** → select the zip → swipe to flash.
4. (Optional) Wipe cache/dalvik.
5. Reboot to system.

AnyKernel3 will:
1. Detect your device (ruan/dizi)
2. Dump the current boot.img from the active slot
3. Replace the kernel with Clyra-Flip
4. Repack and flash the new boot.img
5. Optionally patch vendor_boot with the new DTB

## How It Works

AnyKernel3 uses `magiskboot` to unpack the device's current `boot.img`,
replace the kernel `Image` with the Clyra-Flip build, repack the image, and
flash it to both A/B slots. This preserves the original ramdisk structure and
supports Magisk root retention.

The `vendor_boot` partition (which contains the DTB and modules on SM7435) is
also patched if a DTB is included in the zip.

## License

AnyKernel3 is © osm0sis @ xda-developers. The `LICENSE` file must remain in
the final zip to comply with licenses for binary redistribution.
