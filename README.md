# Clyra-Flip Kernel

**Clyra-Flip** is a high-performance Android Generic Kernel Image (GKI) based on Linux stable **6.6.162 LTS**, built for the Qualcomm Snapdragon 7s Gen 2 (SM7435 / "parrot") platform powering the **Xiaomi Redmi Pad Pro 5G / POCO Pad 5G (`ruan`)** and **Xiaomi Redmi Pad Pro WiFi / POCO Pad WiFi (`dizi`)**.

It delivers a clean, unified experience across HyperOS, AOSP, and custom ROMs, packaged into a single universal flashable AnyKernel3 zip.

---

## Key Highlights

- **Linux 6.6.162 LTS**: Updated upstream long-term stable base.
- **Root Multi-Manager Support**: Out-of-the-box support for both **KernelSU Next (v1.0.5-next)** and **KowSU (v1.0.5-kowsu)** with `/dev/ksun` and `/dev/kowsu` character devices.
- **Advanced Root Concealment**: Integrated **susfs v1.5.5** virtual filesystem with kernel-level isolation for banking apps and Play Integrity.
- **Strict SELinux Enforcing**: Boots and operates strictly in **Enforcing** mode (`selinux_enforcing_boot = 1`), never Permissive.
- **Stock Vendor Compatibility**: Module signature enforcement is disabled (`# CONFIG_MODULE_SIG_FORCE is not set`), ensuring stock Xiaomi `/vendor_dlkm` modules load cleanly without bootloops.
- **Code Aurora Forum (CAF) Platform**: Complete Qualcomm CAF infrastructure covering audio, camera (CAMSS), display (MSM DRM/DPU), power management (SPMI, RPMH, PDC, CPR, LLCC), interconnect, and shared memory (SMEM).
- **Universal Flashable Zip**: Single AnyKernel3 package supporting both devices (`ruan` and `dizi`) across Android 14, 15, 16, and 17 with automatic hardware and ROM detection.
- **Redmi & POCO Pen Support**: Full active stylus support (`BTN_STYLUS`, `BTN_STYLUS2`, pressure sensitivity).
- **Bug Fixes & Stability**: Resolved Kconfig symbol type conflicts, KSU concurrency race conditions, `ksu_revoke_root()` implementation, susfs module lifecycle, `package.sh` error handling and DTB deduplication, and OrangeFox kernel naming compatibility.

---

## Supported Devices & ROMs

### Hardware

| Device Codename | Model Name | Connectivity | SoC | Default Config |
| :--- | :--- | :--- | :--- | :--- |
| **`ruan`** | Redmi Pad Pro 5G / POCO Pad 5G (`2405CPCFAG`) | 5G + WiFi + GNSS | Snapdragon 7s Gen 2 (SM7435) | `arch/arm64/configs/vendor/ruan_GKI.config` |
| **`dizi`** | Redmi Pad Pro WiFi / POCO Pad WiFi (`2405CPCFBG`) | WiFi Only | Snapdragon 7s Gen 2 (SM7435) | `arch/arm64/configs/vendor/dizi_GKI.config` |

### Android & ROM Compatibility

The kernel is ROM-agnostic and compliant with Google Generic Kernel Image (GKI) standards:

| Android Version | GKI Level | Target ROMs | Device Fragment |
| :--- | :--- | :--- | :--- |
| **Android 14** | GKI 2.0 | HyperOS 1, AOSP 14 | `ruan_android14.config` / `dizi_android14.config` |
| **Android 15** | GKI 3.0 | HyperOS 2, AOSP 15 | `ruan_android15.config` / `dizi_android15.config` |
| **Android 16** | GKI 3.1 | HyperOS 3, AOSP 16 | `ruan_android16.config` / `dizi_android16.config` |
| **Android 17** | GKI 4.0 | AOSP 17 / Future ACK | `ruan_android17.config` / `dizi_android17.config` |

Compatible with **HyperOS 1/2/3**, **LineageOS**, **Evolution X**, **crDroid**, **Pixel Experience**, **AOSP**, and other Android derivatives.

---

## Flashing Instructions

Clyra-Flip uses AnyKernel3 to patch the kernel image directly into your active boot slot without wiping or modifying vendor partitions.

### Steps

1. Download the latest universal zip: `clyra-flip-kernel-universal-6.6.162-Clyra-Flip-<timestamp>.zip` from [Releases](https://github.com/isiddharthsarkar/Clyra-Flip/releases).
2. Boot your tablet into custom recovery (**TWRP** or **OrangeFox**).
3. Select **Install** -> Choose the `.zip` file -> **Swipe to Flash**.
4. Reboot to System.

> **Note**: AnyKernel3 auto-detects your device model (`ruan` vs `dizi`) and your installed Android version (14 to 17) automatically. No manual choices are required.
>
> **OrangeFox Note**: The kernel string uses a hyphen (not em dash) so OrangeFox correctly displays the kernel version instead of truncating it.

---

## Building from Source

### Requirements

- Linux build machine (Ubuntu 22.04 LTS or newer recommended)
- AOSP Clang toolchain (`clang-r416183b` for official GKI KMI compatibility)
- Cross-compiler toolchain: `aarch64-linux-gnu-` and `arm-linux-gnueabi-`
- Standard build tools: `make`, `bc`, `bison`, `flex`, `libssl-dev`, `libelf-dev`

### Build Commands

```bash
# Clone the repository
git clone https://github.com/isiddharthsarkar/Clyra-Flip.git
cd Clyra-Flip

# Set your Clang directory
export CLANG_DIR=/path/to/clang-r416183b

# Build for RUAN (Redmi Pad Pro 5G)
./build.sh $CLANG_DIR ruan android14
./build.sh $CLANG_DIR ruan android15
./build.sh $CLANG_DIR ruan android16
./build.sh $CLANG_DIR ruan android17

# Build for DIZI (Redmi Pad Pro WiFi)
./build.sh $CLANG_DIR dizi android14
./build.sh $CLANG_DIR dizi android15
./build.sh $CLANG_DIR dizi android16
./build.sh $CLANG_DIR dizi android17

# Package all builds into the Universal Flashable Zip
./flashable/package.sh .
```

### package.sh Behavior

- **Missing build directories**: If any device+Android combination is missing, `package.sh` reports an error and exits instead of silently producing an incomplete zip.
- **DTB deduplication**: DTBs are saved with Android version suffix (e.g. `dtb_name.android14.dtb`) to prevent different DTBs from different Android versions from overwriting each other.
- **Timestamp**: Zip filenames include a UTC timestamp (`YYYYMMDD-HHMM`) for unique versioning.
- **Modules**: Compiled loadable kernel modules (`.ko`) are harvested from build output and included in the zip.

---

## CI / Workflow Status

**All GitHub Actions CI workflows are disabled.** No workflows start on push. The `build-kernel.yml` workflow remains in the repository for reference but has no `push` trigger. Manual `workflow_dispatch` runs can be triggered from the GitHub Actions tab with `upload_release` defaulting to `false`.

All commits to this repository must include `[skip ci]` in the commit message.

---

## Repository Structure

```
├── arch/arm64/configs/vendor/  # Device and Android version Kconfig fragments
├── build.sh                    # Core build orchestration script
├── build.config.*              # GKI build definitions per device & version
├── drivers/\
│   ├── caf/                    # Qualcomm Code Aurora Forum subsystems
│   │   ├── audio/              # QDSP6 ADSP and WCD audio codec
│   │   ├── camera/             # CAMSS ISP and sensor subsystem
│   │   ├── connectivity/       # ICC, GPIO, PINCTRL, QUPv3 I2C, USB PHY
│   │   ├── display/            # MSM DRM display, DPU, HDMI
│   │   └── power/              # SPMI, PDC, RPMH, CPR, LLCC, clocks
│   └── misc/\
│       └── ksu/                # KernelSU Next, KowSU, and susfs drivers
├── flashable/                  # AnyKernel3 installer templates & packaging
└── .github/workflows/          # GitHub Actions workflow (CI disabled)
```

---

## Bug Fixes (v1.0.0)

| Area | Bug | Fix |
| :--- | :--- | :--- |
| **OrangeFox naming** | Em dash in `kernel.string` caused OrangeFox to show "5.10.69 caramel v2" | Replaced em dash with hyphen in `flashable/anykernel.sh` |
| **Kconfig duplicates** | Duplicate `QCOM_CPR`, `QCOM_RPMH`, `QCOM_GENI_SE`, `QCOM_SMEM`, `QCOM_LLCC`, `QCOM_RMTFS_MEM`, `QCOM_SMD_RPM` across `drivers/caf/Kconfig`, `drivers/caf/power/Kconfig`, and `drivers/soc/qcom/Kconfig` | Removed duplicates from CAF Kconfigs; canonical copies retained in `drivers/soc/qcom/Kconfig` |
| **KSU race condition** | `ksu_proc_find()` called outside `mutex_lock()` in `ksu_proc_add()`, causing TOCTOU race | Moved `ksu_proc_find()` inside the mutex lock |
| **ksu_revoke_root()** | Was a no-op (`return 0`) | Implemented with `prepare_creds()`/`commit_creds()` to actually revoke root credentials |
| **susfs lifecycle** | `ksu_susfs_unregister()` not called in `ksu_exit()`, leaking filesystem registration | Added `ksu_susfs_unregister()` call in `ksu_exit()` |
| **KSU Makefile** | Redundant `ksu-y`/`susfs-y` object definitions | Cleaned up to single definitions each |
| **package.sh silent failure** | Missing build dirs caused silent `continue`, producing incomplete zips | Hard error on missing build dirs/images with clear `ERROR` messages |
| **package.sh DTB dedup** | DTBs deduplicated by filename only, causing cross-Android-version overwrites | DTB filenames now include Android version suffix |

---

## License

This project is licensed under the **GNU General Public License v2.0** (`GPL-2.0`). See [COPYING](COPYING) for details.

---

## Related Repositories

- **Clyra-Vendor**: https://github.com/isiddharthsarkar/Clyra-Vendor — Vendor blobs, device trees, and HAL implementations for Xiaomi ruan/dizi (SM7435). Fully compatible with Clyra-Flip kernel builds.
