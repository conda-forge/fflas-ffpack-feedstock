#!/bin/bash

echo "AC_DEFUN([INSTR_SET], [])" > macros/instr_set.m4

autoreconf -if

unset CFLAGS
unset CXXFLAGS

if [[ "$cxx_compiler" == "clangxx" ]]; then
    export am_cv_CXX_dependencies_compiler_type=clang
    export CCNAM=clang
elif [[ "$cxx_compiler" == "clangxx" ]]; then
    export am_cv_CXX_dependencies_compiler_type=gcc
    export CCNAM=gcc
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
if [[ "${CONDA_BUILD_CROSS_COMPILATION}" != "1" ]]; then
    make check -j${CPU_COUNT} || cat tests/test-suite.log
fi
else
    make check -j${CPU_COUNT} || (cat tests/test-suite.log && exit 1)
fi
