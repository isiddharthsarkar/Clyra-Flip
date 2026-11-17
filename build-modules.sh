#!/bin/bash
# Build the external vendor modules against the ruan 6.6 kernel, in the
# order of TARGET_KERNEL_EXT_MODULES, the way the ROM build does (vendor/
# lineage kernel.mk): each directory through its own Makefile and default
# target, with M relative to the kernel source. Each Makefile names the
# Module.symvers it depends on.
#   build-modules.sh [module dir ...]
K=$(cd "$(dirname "$0")" && pwd)
O=${O:-$K/../out-ruan66}
MODS_REL=../sm7435-modules
export PATH=$K/../clang-r563880c/bin:$PATH
LIST=${@:-"
qcom/opensource/mmrm-driver
qcom/opensource/audio-kernel
qcom/opensource/camera-kernel
qcom/opensource/datarmnet-ext/mem
qcom/opensource/dataipa/drivers/platform/msm
qcom/opensource/datarmnet/core
qcom/opensource/datarmnet-ext/aps
qcom/opensource/datarmnet-ext/offload
qcom/opensource/datarmnet-ext/shs
qcom/opensource/datarmnet-ext/perf
qcom/opensource/datarmnet-ext/perf_tether
qcom/opensource/datarmnet-ext/sch
qcom/opensource/datarmnet-ext/wlan
qcom/opensource/securemsm-kernel
qcom/opensource/mm-drivers/msm_ext_display
qcom/opensource/mm-drivers/sync_fence
qcom/opensource/synx-kernel-v1
qcom/opensource/display-drivers/msm
qcom/opensource/eva-kernel-v1
qcom/opensource/graphics-kernel
qcom/opensource/bt-kernel
qcom/opensource/dsp-kernel
qcom/opensource/touch-drivers
qcom/opensource/video-driver
qcom/opensource/wlan/platform
qcom/opensource/wlan/qcacld-3.0/.adrastea
nxp/opensource/driver
"}
SYMS=""
mkdir -p $O/ext-logs
fail=0
for m in $LIST; do
	log=$O/ext-logs/$(echo $m | tr / _).log
	if make -C $K/$MODS_REL/$m KERNEL_SRC=$K M=$MODS_REL/$m O=$O OUT_DIR=$O ARCH=arm64 LLVM=1 LLVM_IAS=1 \
		HOSTCFLAGS="-I/usr/include/openssl-3" HOSTLDFLAGS="-L/usr/lib/openssl-3 -Wl,-rpath,/usr/lib/openssl-3" \
		TARGET_BOARD_PLATFORM=parrot TARGET_PRODUCT=ruan -j$(nproc) > $log 2>&1; then
		n=$(find $K/$MODS_REL/$m -name "*.ko" | wc -l)
		echo "OK   $m ($n modules)"
	else
		echo "FAIL $m (see $log)"; fail=1
	fi
	[ -f $K/$MODS_REL/$m/Module.symvers ] && SYMS="$SYMS $K/$MODS_REL/$m/Module.symvers"
done
exit $fail
