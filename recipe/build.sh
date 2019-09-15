#!/bin/bash

autoreconf -i

unset CFLAGS
unset CXXFLAGS

if [[ $(uname) == "Linux" ]]; then
    export LDFLAGS="$LDFLAGS -Wl,-rpath-link,$PREFIX/lib"
fi

chmod +x configure
# Enable only SSE/SSE2 as these are supported on all 64bit CPUs
# https://unix.stackexchange.com/a/249384
./configure \
    --prefix="$PREFIX" \
    --libdir="$PREFIX/lib" \
    --with-default="$PREFIX" \
    --with-blas-libs="-llapack -lblas" \
    --enable-optimization \
    --enable-precompilation \
    --disable-openmp \
    --enable-sse \
    --enable-sse2 \
    --disable-sse3 \
    --disable-ssse3 \
    --disable-sse41 \
    --disable-sse42 \
    --disable-avx \
    --disable-avx2 \
    --disable-fma \
    --disable-fma4 \
    --disable-avx512f \
    --disable-avx512dq \
    --disable-avx512vl

make -j${CPU_COUNT}
make install

if [[ "$PKG_VERSION" == "2.4.3" && "$target_platform" == "osx-64" ]]; then
    make check -j${CPU_COUNT} || cat tests/test-suite.log
else
    make check -j${CPU_COUNT} || (cat tests/test-suite.log && exit 1)
fi
