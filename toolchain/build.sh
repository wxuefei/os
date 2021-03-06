#!/bin/bash

set -e

. ../build/buildfuncs.sh

BINUTILSVER=binutils-2.32
GCCVERNUM=8.3.0
GCCVER=gcc-${GCCVERNUM}
PREFIX=`pwd`/cross-$GCCVERNUM
LOGDIR=`pwd`/logs
PATH="$PATH:$PREFIX/bin"

mkdir -p src "$PREFIX" "$LOGDIR"
cd src

GET ftp://ftp.nluug.nl/mirror/gnu/binutils "${BINUTILSVER}.tar.xz" 0ab6c55dd86a92ed561972ba15b9b70a8b9f75557f896446c82e8b36e473ee04
GET ftp://ftp.nluug.nl/mirror/languages/gcc/releases/$GCCVER "${GCCVER}.tar.xz" 64baadfe6cc0f4947a84cb12d7f0dfaf45bb58b7e92461639596c21e02d97d2c

unpack "$BINUTILSVER"
unpack "$GCCVER"
#unpack "$MPFRVER" "$GCCVER/mpfr"
#unpack "$GMPVER" "$GCCVER/gmp"
#unpack "$MPCVER" "$GCCVER/mpc"

mkdir -p build-$BINUTILSVER
cd build-$BINUTILSVER
setlog binutils_configure
CONFIGURE "$BINUTILSVER" --target=$TARGET --prefix="$PREFIX" --with-sysroot --disable-nls --disable-werror
setlog binutils_build
MAKE
MAKE install
clearlog
cd ..

# Check that binutils installed successfully and is in path
which -- $TARGET-as >/dev/null || echo $TARGET-as is not in the PATH

mkdir -p build-$GCCVER
cd build-$GCCVER
setlog gcc_configure
CONFIGURE "$GCCVER" --target=$TARGET --prefix="$PREFIX" --disable-nls --enable-languages=c,c++ --without-headers --disable-libstdcxx
setlog gcc_build
MAKE all-gcc all-target-libgcc
MAKE install-strip-gcc install-strip-target-libgcc
clearlog
cd ..
