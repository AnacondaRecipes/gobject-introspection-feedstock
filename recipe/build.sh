#! /bin/bash

set -e
IFS=$' \t\n' # workaround for conda 4.2.13+toolchain bug

# export PKG_CONFIG_LIBDIR=${PREFIX}/lib/pkgconfig:${PREFIX}/share/pkgconfig

# TODO :: Fix this in pkg-config directly. It needs to check for CONDA_BUILD_SYSROOT
#         and prepend these values to PKG_CONFIG_PATH and default to --define-prefix
#         (the same issue came up in libxcb-feedstock).
if [[ ${HOST} =~ .*x86_64.* ]]; then
  SRLIBDIR=lib64
else
  SRLIBDIR=lib
fi
echo "#!/usr/bin/env bash"                                                                                                                            > ./pkg-config
echo "export PKG_CONFIG_PATH=${PREFIX}/lib/pkgconfig:$(${CC} -print-sysroot)/usr/share/pkgconfig:$(${CC} -print-sysroot)/usr/${SRLIBDIR}/pkgconfig"  >> ./pkg-config
echo "${PREFIX}/bin/pkg-config --define-prefix \"\$@\""                                                                                              >> ./pkg-config
chmod +x ./pkg-config
export PATH=${PWD}:${PATH}
export PKG_CONFIG=${PWD}/pkg-config

declare -a configure_args

configure_args+=(--prefix=${PREFIX})
configure_args+=(--host=${HOST})
configure_args+=(--disable-dependency-tracking)
configure_args+=(--with-cairo)
# TODO :: Remove the True here, it is working around a conda-build bug.
if [[ ${PY3K} == True ]] || [[ ${PY3K} == 1 ]]; then
  configure_args+=(--with-python=${PYTHON}3)
else
  configure_args+=(--with-python=${PYTHON})
fi

if [ $(uname) = Darwin ] ; then
    LDFLAGS="$LDFLAGS -Wl,-rpath,$PREFIX/lib"
fi

./configure "${configure_args[@]}" || { cat config.log ; exit 1 ; }
make -j${CPU_COUNT} ${VERBOSE_AT}
make install

if [ -z "$OSX_ARCH" ] ; then
    echo "Skipping make check on linux due to libtool cross bug"
    # make check
else
    # Test suite does not fully work on OSX, but not because anything is broken.
    make check-local check-TESTS
    (cd tests && make check-TESTS) || exit 1
    (cd tests/offsets && make check) || exit 1
    (cd tests/warn && make check) || exit 1
fi

rm -f $PREFIX/lib/libgirepository-*.a $PREFIX/lib/libgirepository-*.la
