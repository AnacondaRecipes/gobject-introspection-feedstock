#! /bin/bash

set -ex

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
meson --buildtype=release --prefix="$PREFIX" --wrap-mode=nofallback --backend=ninja -Dlibdir=lib \
      -Dcairo=enabled -Dpython="$PYTHON" ..
ninja -v

if [ ! -f "$SRC_DIR/forgebuild/girepository/libregress-1.0${SHLIB_EXT}" ]; then
  # libregress library, used in testing only, is not found at test time, failing test gitypelibtest
  # creating the following symlink circumvent this issue 
  # similar issues reported here:
  # See https://github.com/macports/macports-ports/blame/master/gnome/gobject-introspection/Portfile
  # See https://github.com/NixOS/nixpkgs/commit/52f82285f68116aa2d4559ef9628ebfd90b8f336

  ln -s $SRC_DIR/forgebuild/tests/scanner/libregress-1.0${SHLIB_EXT} $SRC_DIR/forgebuild/girepository/libregress-1.0${SHLIB_EXT}
  ninja test
  rm $SRC_DIR/forgebuild/girepository/libregress-1.0${SHLIB_EXT}
else
  ninja test
fi

ninja install

rm -f $PREFIX/lib/libgirepository-*.a $PREFIX/lib/libgirepository-*.la