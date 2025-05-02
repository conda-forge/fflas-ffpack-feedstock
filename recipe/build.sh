#!/bin/bash

echo "AC_DEFUN([INSTR_SET], [])" > macros/instr_set.m4
sed -i.bak "s/AC_COMPILER_NAME//g" configure.ac

autoreconf -if

unset CFLAGS
unset CXXFLAGS

if [[ "$cxx_compiler" == "clangxx" ]]; then
    export CCNAM=clang
elif [[ "$cxx_compiler" == "gxx" ]]; then
    export CCNAM=gcc
fi

chmod +x configure
# Enable only SSE/SSE2 as these are supported on all 64bit CPUs
# https://unix.stackexchange.com/a/249384
./configure \
    --prefix="$PREFIX" \
    --libdir="$PREFIX/lib" \
    --with-default="$PREFIX" \
    --with-blas-libs="-llapack -lcblas -lblas" \
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
    --disable-avx512vl || (cat config.log; false)

make -j${CPU_COUNT}
make install

if [[ "${CONDA_BUILD_CROSS_COMPILATION}" != "1" ]]; then
    # Provide information requested by https://github.com/linbox-team/fflas-ffpack/issues/408#issuecomment-2770670149
    make check -j${CPU_COUNT} || (cat tests/test-suite.log && ldd tests/test-echelon && exit 1)
fi
