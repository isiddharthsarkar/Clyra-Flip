#!/bin/bash
# ruan 6.6 kernel build, same config as the ROM: gki_defconfig + parrot + ruan + debugfs.
set -e
K=$(cd "$(dirname "$0")" && pwd)
O=${O:-$K/../out-ruan66}
export PATH=$K/../clang-r563880c/bin:$PATH
export HOSTCFLAGS="-I/usr/include/openssl-3" HOSTLDFLAGS="-L/usr/lib/openssl-3 -Wl,-rpath,/usr/lib/openssl-3"
M="make -C $K O=$O ARCH=arm64 LLVM=1 LLVM_IAS=1 HOSTCFLAGS=$HOSTCFLAGS HOSTLDFLAGS=$HOSTLDFLAGS"
$M gki_defconfig vendor/parrot_GKI.config vendor/ruan_GKI.config vendor/debugfs.config
[ $# -gt 0 ] || set -- Image modules dtbs
$M -j$(nproc) "$@"
