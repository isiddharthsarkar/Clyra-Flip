#!/bin/bash
# Build one external module directory (from sm7435-modules) against the ruan 6.6 kernel.
#   build-ext.sh qcom/opensource/audio-kernel [extra make args]
set -e
K=$(cd "$(dirname "$0")" && pwd)
O=${O:-$K/../out-ruan66}
MODS=${MODS:-$K/../sm7435-modules}
D=$MODS/$1; shift
export PATH=$K/../clang-r563880c/bin:$PATH
make -C $K O=$O ARCH=arm64 LLVM=1 LLVM_IAS=1 \
	HOSTCFLAGS="-I/usr/include/openssl-3" HOSTLDFLAGS="-L/usr/lib/openssl-3 -Wl,-rpath,/usr/lib/openssl-3" \
	M=$D KERNEL_SRC=$K AUDIO_ROOT=$D DISPLAY_ROOT=$D MSM_EXT_DISPLAY_ROOT=$D SYNC_FENCE_ROOT=$D MODNAME=${MODNAME:-audio_dlkm} \
	KBUILD_EXTRA_SYMBOLS="${EXTRA_SYMBOLS}" -j$(nproc) modules "$@"
