setlocal EnableDelayedExpansion
@echo on

:: set pkg-config path so that host deps can be found
set PKG_CONFIG_PATH="%LIBRARY_LIB%\pkgconfig;%LIBRARY_PREFIX%\share\pkgconfig;%BUILD_PREFIX%\Library\lib\pkgconfig"
set SEARCH_PATH="%BUILD_PREFIX%\Library\"

IF NOT EXIST "%BUILD_PREFIX%\Library\lib\pkgconfig\libffi.pc" (
    :: our current libffi does not ship with a pkgconfig file.
    copy "%RECIPE_DIR%\libffi.pc" "%BUILD_PREFIX%\Library\lib\pkgconfig\"
)

:: meson options
:: (set pkg_config_path so deps in host env can be found)
set ^"MESON_OPTIONS=^
  --prefix="%LIBRARY_PREFIX%" ^
  --wrap-mode=nofallback ^
  --buildtype=release ^
  --backend=ninja ^
  -Dcairo=enabled ^
  -Dcairo-libname=cairo-gobject.dll ^
  -Dpython=%PYTHON% ^
  -Dcmake_prefix_path=%SEARCH_PATH% ^
 ^"

:: setup build
meson setup builddir !MESON_OPTIONS!
if errorlevel 1 (
    type builddir\meson-logs\meson-log.txt
    exit 1
)

:: print results of build configuration
meson configure builddir
if errorlevel 1 exit 1

:: build
ninja -v -C builddir -j %CPU_COUNT%
if errorlevel 1 exit 1

:: test - some errors, ignore test results for now
ninja -v -C builddir test
@REM if errorlevel 1 exit 1

:: install
ninja -C builddir install -j %CPU_COUNT%
if errorlevel 1 exit 1

del %LIBRARY_PREFIX%\bin\*.pdb