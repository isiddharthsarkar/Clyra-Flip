#!/bin/bash
# Test images for the ruan 6.6 kernel on an installed ROM (no ROM build).
#
#   ruan/mkimg66.sh <dir with the ROM's boot.img and vendor_boot.img>
#
# boot66.img         the ROM's boot image with the 6.6 kernel
# vendor_boot66.img  the 6.6 base dtb (parrot + SoC overlays) and every
#                    ruan 6.6 module in the vendor ramdisk, loaded by first
#                    stage init
# dtbo66.img         ruan's board, display, audio and camera overlays merged
#                    into one entry (as the ROM build's merge_dtbs.py does),
#                    applied by the bootloader. The bootloader needs a real
#                    board overlay: an empty entry drops it to fastboot.
#
# The ROM's own 5.10 modules on vendor_dlkm fail to load, which is harmless.
# Flash all three; flash the saved stock images back to return.
#
# Environment: O (kernel out, ../out-ruan66), MODS (../sm7435-modules),
# MERGE (fdtoverlaymerge, built from LineageOS android_external_dtc),
# DEV (device tree with modules/ lists), CMDLINE (extra vendor cmdline).
set -euo pipefail
K=$(cd "$(dirname "$0")/.." && pwd)
W=$(cd "${1:?ROM image dir}" && pwd)
O=${O:-$K/../out-ruan66}
MODS=${MODS:-$K/../sm7435-modules}
DEV=${DEV:-/mnt/directstorage/trees/device_xiaomi_ruan}
T=$W/tmp66
CLANG=$K/../clang-r563880c/bin
MERGE=${MERGE:-$K/../tools/lin-dtc/fdtoverlaymerge}
rm -rf "$T" && mkdir -p "$T"

D=$O/arch/arm64/boot/dts/vendor/qcom
fdtoverlay -i $D/parrot.dtb -o $T/ruan66.dtb \
	$D/display/display/parrot-sde.dtbo $D/camera/parrot-camera.dtbo \
	$D/audio/parrot-audio.dtbo $D/data/parrot-ipa.dtbo \
	$D/dsp/parrot/parrot-dsp.dtbo $D/graphics/gpu/parrot-gpu.dtbo \
	$D/nfc/nxp/parrot-nfc.dtbo $D/video/parrot-vidc.dtbo

# dtbo: ruan's four overlays merged into one entry
$MERGE -i $D/ruan-sm7435-overlay.dtbo $D/display/display/ruan-sde-display-overlay.dtbo \
	$D/audio/ruan-audio-qrd.dtbo $D/camera/ruan-camera-sensor.dtbo -o $T/ruan.dtbo >/dev/null
mkdtboimg create $W/dtbo66.img --page_size=4096 $T/ruan.dtbo

# modules: all lists, in load order, stripped, with a fresh modules.dep
REL=$(cat $O/include/config/kernel.release)
L=$T/lib/modules; mkdir -p $L
lists="$K/modules.list.msm.parrot $DEV/modules/modules.list.first_stage $DEV/modules/modules.list.second_stage $DEV/modules/modules.list.vendor_dlkm"
grep -hv '^\s*#' $lists | grep . | awk '!seen[$0]++' > $T/order
# Pull in every dependency of the listed modules, as the ROM build does with
# TARGET_AUTO_COLLECT_KERNEL_MODULE_DEPS (modules.dep lets modprobe load them).
find $O $MODS -name "*.ko" > $T/all
findko() { grep -m1 -E "/($1|$(echo $1 | tr _ -)|$(echo $1 | tr - _))\.ko$" $T/all || true; }
todo=$(sed 's/\.ko$//' $T/order); done_=" "
while [ -n "$todo" ]; do
	next=""
	for m in $todo; do
		case "$done_" in *" $m "*) continue;; esac
		done_="$done_$m "
		f=$(findko $m)
		[ -n "$f" ] || { echo "missing $m" >&2; continue; }
		$CLANG/llvm-strip --strip-debug -o $L/$(basename $f) $f
		next="$next $(modinfo -F depends $f | tr ',' ' ')"
	done
	todo=$next
done
mkdir -p $T/depmod/lib/modules/$REL && cp $L/*.ko $T/depmod/lib/modules/$REL/
depmod -b $T/depmod $REL
cp $T/depmod/lib/modules/$REL/modules.dep $T/depmod/lib/modules/$REL/modules.alias $T/depmod/lib/modules/$REL/modules.softdep $L/
sed -i "s|[^ :]*/\([^/ :]*\.ko\)|/lib/modules/\1|g" $L/modules.dep
cp $T/order $L/modules.load
cp $T/order $L/modules.load.recovery
echo "$(wc -l < $T/order) modules"

python3 -I - "$W" "$T" "${CMDLINE:-}" <<'EOF'
import os, shlex, shutil, subprocess, sys
w, t, extra = sys.argv[1:]
def run(*a, **kw): return subprocess.run(a, check=True, **kw)
args = shlex.split(run('unpack_bootimg', '--boot_img', w + '/vendor_boot.img',
                       '--out', t + '/vb', '--format', 'mkbootimg',
                       capture_output=True, text=True).stdout)
def swap_modules(src, dst):
    d = dst + '.d'; os.makedirs(d)
    raw = open(src, 'rb').read()
    if raw[:4] in (b'\x02\x21\x4c\x18', b'\x04\x22\x4d\x18'):
        raw = run('lz4', '-dc', src, capture_output=True).stdout
    elif raw[:2] == b'\x1f\x8b':
        raw = run('gzip', '-dc', src, capture_output=True).stdout
    run('cpio', '-idm', '--quiet', input=raw, cwd=d)
    shutil.rmtree(d + '/lib/modules', ignore_errors=True)
    shutil.copytree(t + '/lib/modules', d + '/lib/modules')
    files = run('find', '.', capture_output=True, text=True, cwd=d).stdout
    files = ''.join(sorted(l + '\n' for l in files.split('\n') if l))
    cpio = run('cpio', '-o', '-H', 'newc', '--quiet', '-R', '0:0',
               input=files.encode(), capture_output=True, cwd=d).stdout
    open(dst, 'wb').write(run('lz4', '-l', '-12', '--favor-decSpeed', '-q', '-c',
                              input=cpio, capture_output=True).stdout)
out, i, frag = [], 0, 0
while i < len(args):
    a = args[i]
    if a == '--dtb':
        out += [a, t + '/ruan66.dtb']; i += 2; continue
    if a == '--vendor_ramdisk_fragment':
        dst = f'{t}/vendor_ramdisk{frag:02d}'
        if frag == 0: swap_modules(args[i + 1], dst)
        else: shutil.copy(args[i + 1], dst)
        out += [a, dst]; frag += 1; i += 2; continue
    if a == '--vendor_cmdline':
        cmd = args[i + 1] + ' clk_ignore_unused pd_ignore_unused'
        if extra: cmd += ' ' + extra
        out += [a, cmd]; i += 2; continue
    out.append(a); i += 1
run('mkbootimg', *out, '--vendor_boot', f'{w}/vendor_boot66.img')
EOF

# boot: the ROM's generic ramdisk with the 6.6 kernel
python3 -I - "$W" "$T" "$O/arch/arm64/boot/Image" <<'EOF'
import shlex, subprocess, sys
w, t, image = sys.argv[1:]
args = shlex.split(subprocess.run(['unpack_bootimg', '--boot_img', w + '/boot.img',
    '--out', t + '/b', '--format', 'mkbootimg'], check=True, capture_output=True, text=True).stdout)
out, i = [], 0
while i < len(args):
    if args[i] == '--kernel': out += ['--kernel', image]; i += 2; continue
    out.append(args[i]); i += 1
subprocess.run(['mkbootimg', *out, '--output', w + '/boot66.img'], check=True)
EOF
ls -la "$W"/boot66.img "$W"/vendor_boot66.img "$W"/dtbo66.img
echo "kernel $REL"
