# Clyra-Flip Flashable Zip (TWRP / OrangeFox)

This directory contains the files needed to package the Clyra-Flip kernel
into a flashable zip installable via TWRP or OrangeFox recovery.

## Files

- `META-INF/com/google/android/updater-script` — Edify script that flashes
  `boot.img`, `dtbo.img`, and `vendor_boot.img` to both A/B slots.
- `package.sh` — Script that builds `boot.img` and `dtbo.img` from the
  kernel build output and packages everything into a flashable zip.

## Building the flashable zip

### Prerequisites

The following tools must be installed:
- `mkbootimg` (from Android `mkbootimg` or `android-tools`)
- `mkdtboimg` (from Android `dtbtools` or `android-tools`)
- `zip`

### Build the kernel first

```sh
# ruan (Redmi Pad Pro 5G / POCO Pad 5G)
./build.sh ruan android16

# dizi (Redmi Pad Pro WiFi / POCO Pad WiFi)
./build.sh dizi android16
```

### Package the flashable zip

```sh
# Basic usage (boot.img + dtbo.img built from kernel output;
# vendor_boot.img placeholder - you must provide a real one)
./flashable/package.sh out-ruan66

# With a stock vendor_boot.img extracted from your device ROM
./flashable/package.sh out-ruan66 /path/to/vendor_boot.img
```

This produces:
```
clyra-flip-kernel-ruan-6.6.144-Clyra-Flip.zip
```

## Flashing

1. Copy the `.zip` to your device's internal storage or USB-OTG drive.
2. Reboot to TWRP / OrangeFox recovery.
3. **Install** → select the zip → swipe to flash.
4. **Wipe cache/dalvik** (recommended but optional).
5. Reboot to system.

### vendor_boot.img requirement

The zip includes `vendor_boot.img`, which must be a real image for the
device to boot after flashing. You can:

- Extract `vendor_boot.img` from your stock ROM firmware package.
- Use the stock `vendor_boot.img` from your current installation
  (e.g. via `dd` from the `vendor_boot_a`/`vendor_boot_b` partition).

Pass it as the second argument to `package.sh` so it is included in the zip.

## Supported devices

| Device | Variant | Out dir example |
|--------|---------|-----------------|
| ruan   | Redmi Pad Pro 5G / POCO Pad 5G | `out-ruan66` |
| dizi   | Redmi Pad Pro WiFi / POCO Pad WiFi | `out-dizi66` |

## Android versions

The flashable zip works with kernels built for any supported Android
release (Android 14/15/16/17 → GKI 2.0/3.0/3.1/4.0), since they all use
the same kernel binary format.
