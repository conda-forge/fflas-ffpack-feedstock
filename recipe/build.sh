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

# Statically link in openblas since fflas-ffpack require a single threaded blas.
# If linked dynamically, it will make openblas single threaded for the entire
# process since fflas uses openblas_set_num_threads(1)
if [[ "$target_platform" == "linux-"* ]]; then
    BLAS_LIBS="-L${PREFIX}/lib -Wl,--exclude-libs,libopenblas.a -lgfortran"
elif [[ "$target_platform" == "osx-"* ]]; then
    BLAS_LIBS="-L${PREFIX}/lib -hidden-lopenblas -lgfortran"
fi

chmod +x configure
# Enable only SSE/SSE2 as these are supported on all 64bit CPUs
# https://unix.stackexchange.com/a/249384
./configure \
    --prefix="$PREFIX" \
    --libdir="$PREFIX/lib" \
    --with-default="$PREFIX" \
    --with-blas-libs="${BLAS_LIBS}" \
    --enable-precompilation \
    --disable-openmp \
    --without-archnative || (cat config.log; false)

make -j${CPU_COUNT}
make install

if [[ "${CONDA_BUILD_CROSS_COMPILATION}" != "1" ]]; then
    # Provide information requested by https://github.com/linbox-team/fflas-ffpack/issues/408#issuecomment-2770670149
    make check -j${CPU_COUNT} || (cat tests/test-suite.log && ldd tests/test-echelon && exit 1)
fi
