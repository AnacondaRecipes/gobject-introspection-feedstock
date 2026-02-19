#!/usr/bin/env bash

set -euxo pipefail

if [[ "$target_platform" == osx-* ]] ; then
    # dead_strip_dylibs breaks some tests
    LDFLAGS=${LDFLAGS//-Wl,-dead_strip_dylibs/}
fi

mkdir -p $PREFIX/libexec
cp $RECIPE_DIR/load.sh $PREFIX/libexec/gi-cross-launcher-load.sh
cp $RECIPE_DIR/save.sh $PREFIX/libexec/gi-cross-launcher-save.sh

export PKG_CONFIG=$BUILD_PREFIX/bin/pkg-config

mkdir forgebuild
cd forgebuild
meson ${MESON_ARGS} \
    --prefix="$PREFIX" \
    --backend=ninja \
    -Dlibdir=lib \
    -Dcairo=enabled \
    -Dpython="$PYTHON" \
    ..

ninja -v -j${CPU_COUNT}
ninja install -j${CPU_COUNT}

rm -f $PREFIX/lib/libgirepository-*.a $PREFIX/lib/libgirepository-*.la
