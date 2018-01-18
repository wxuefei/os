#!/bin/bash
# Requires that you've already built the toolchain in toolchain/cross-X/bin

. ../build/buildfuncs.sh

GRUBVER=grub-2.02
PREFIX=`pwd`/prefix-$GRUBVER
LOGDIR=`pwd`/logs
PATH="$PATH:$PREFIX/bin"

set -e

mkdir -p src "$PREFIX" "$LOGDIR"

recv_keys E53D497F3FA42AD8C9B4D1E835A93B75E82E4209

cd src

GET ftp://ftp.nluug.nl/mirror/gnu/grub/ "${GRUBVER}.tar.xz" 810b3798d316394f94096ec2797909dbf23c858e48f7b3830826b8daa06b7b0f
unpack "${GRUBVER}"

toolchainBin=`pwd`/../../toolchain/cross-7.1.0/bin

[ -d "$toolchainBin" -a -x "$toolchainBin/$TARGET-gcc" ] ||
    die "$toolchainBin/$TARGET-gcc not found or not executable - build cross toolchain first?"

export PATH="$PATH:$toolchainBin"

mkdir -p build-$GRUBVER
cd build-$GRUBVER
setlog grub_configure
CONFIGURE "$GRUBVER" -C --disable-werror --target=$TARGET --prefix="$PREFIX" TARGET_CC="ccache $TARGET-gcc" HOST_CC="ccache gcc"
setlog grub_build
r $MAKE
r $MAKE install
clearlog
cd ..

if ! command -v xorriso >/dev/null; then
    echo >&2 "Warning: xorriso is not installed - will be required for grub-mkrescue"
fi