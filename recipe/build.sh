#! /bin/bash

set -ex

if [ $(uname) = Darwin ] ; then
    LDFLAGS="$LDFLAGS -Wl,-rpath,$PREFIX/lib"
    # dead_strip_dylibs breaks some tests
    LDFLAGS=${LDFLAGS//-Wl,-dead_strip_dylibs/}
else
    LDFLAGS="$LDFLAGS -Wl,-rpath-link,$PREFIX/lib"
fi

mkdir forgebuild
cd forgebuild
meson --buildtype=release --prefix="$PREFIX" --backend=ninja -Dlibdir=lib \
      -Dcairo=enabled -Dpython="$PYTHON" ..
ninja -v
ninja test
ninja install

rm -f $PREFIX/lib/libgirepository-*.a $PREFIX/lib/libgirepository-*.la

sed -i.bak 's|g_ir_scanner=${bindir}/g-ir-scanner|g_ir_scanner=python ${bindir}/g-ir-scanner|g' "${PREFIX}"/lib/pkgconfig/gobject-introspection-1.0.pc
sed -i.bak 's|g_ir_scanner=${bindir}/g-ir-scanner|g_ir_scanner=python ${bindir}/g-ir-scanner|g' "${PREFIX}"/lib/pkgconfig/gobject-introspection-no-export-1.0.pc
# diff -urN "${PREFIX}"/lib/pkgconfig/gobject-introspection-1.0.pc.bak "${PREFIX}"/lib/pkgconfig/gobject-introspection-1.0.pc
# diff -urN "${PREFIX}"/lib/pkgconfig/gobject-introspection-no-export-1.0.pc.bak "${PREFIX}"/lib/pkgconfig/gobject-introspection-no-export-1.0.pc
rm "${PREFIX}"/lib/pkgconfig/gobject-introspection-1.0.pc.bak "${PREFIX}"/lib/pkgconfig/gobject-introspection-no-export-1.0.pc.bak
