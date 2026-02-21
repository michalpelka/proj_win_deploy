@echo off
setlocal ENABLEDELAYEDEXPANSION

@REM echo === Loading MSVC environment (required for Ninja + cl) ===
@REM call "%ProgramFiles%\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat"
@REM if %errorlevel% neq 0 (
@REM echo ERROR: Could not load MSVC toolchain
@REM exit /b 1
@REM )

echo === Checking Ninja ===
where ninja >nul 2>nul
if %errorlevel% neq 0 (
echo ERROR: Ninja not found in PATH. Install with: winget install Ninja-build.Ninja
exit /b 1
)

echo === Resolve SQLite folder ===
for /d %%D in (sqlite-amalgamation-*) do (
set SQLITE_DIR=%%D
)
if not defined SQLITE_DIR (
echo ERROR: sqlite-amalgamation-* folder not found
exit /b 1
)
echo Using SQLITE_DIR=!SQLITE_DIR!

echo === Building zlib (static /MD) ===
cmake --fresh -S zlib -B build_zlib -G Ninja ^
-DCMAKE_INSTALL_PREFIX=%CD%\install_zlib ^
-DCMAKE_BUILD_TYPE=Release ^
-DBUILD_SHARED_LIBS=OFF ^
-DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreadedDLL

cmake --build build_zlib
cmake --install build_zlib

set ZLIB_ROOT=%CD%\install_zlib
set ZLIB_DIR=%CD%\install_zlib

echo === Building libtiff (minimal static, no extra codecs) ===
cmake --fresh -S libtiff -B build_tiff -G Ninja ^
-DCMAKE_BUILD_TYPE=Release ^
-DCMAKE_PREFIX_PATH=%CD%\install_zlib\lib\cmake\zlib ^
-DCMAKE_INSTALL_PREFIX=%CD%\install_tiff ^
-DBUILD_SHARED_LIBS=OFF ^
-Dtiff-tools=OFF ^
-Dtiff-tests=OFF ^
-Dtiff_static=ON ^
-Dzlib=ON ^
-Djpeg=OFF ^
-Dwebp=OFF ^
-Dzstd=OFF ^
-Dlzma=OFF ^
-DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreadedDLL 

cmake --build build_tiff
cmake --install build_tiff


echo === Ensuring sqlite3.exe (for PROJ build sanity) ===
echo Using sqlite3.exe at: %CD%\sqlite_exe\sqlite3.exe

echo === Testing sqlite3 ===
sqlite_exe\sqlite3.exe --version
if %errorlevel% neq 0 (
    echo ERROR: sqlite3.exe failed to run
    exit /b 1
)

echo === Building SQLite (static /MD) ===
pushd !SQLITE_DIR!
cl /O2 /MD /c sqlite3.c
if %errorlevel% neq 0 exit /b 1
lib sqlite3.obj /OUT:sqlite3.lib
popd

echo ==== Patch PROJ ==============================
cd proj
git apply ..\proj.patch
if %errorlevel% neq 0 (
echo WARNING: Patch may already be applied or failed, continuing...
)
cd ..

echo === Configure PROJ (Ninja + CMake 4.x fix) ===
cmake --fresh -S PROJ -B build_proj -G Ninja ^
  -DCMAKE_PREFIX_PATH="%CD%\install_zlib;%CD%\install_tiff;" ^
  -DCMAKE_INSTALL_PREFIX=%CD%\install_proj ^
  -DCMAKE_BUILD_TYPE=Release ^
  -DCMAKE_POLICY_VERSION_MINIMUM=3.5 ^
  -DBUILD_SHARED_LIBS=ON ^
  -DBUILD_APPS=OFF ^
  -DBUILD_TESTING=OFF ^
  -DENABLE_TIFF=ON ^
  -DENABLE_CURL=OFF ^
  -DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreadedDLL ^
  -DEXE_SQLITE3=%CD%\sqlite_exe\sqlite3.exe ^
  -DSQLITE3_INCLUDE_DIR=%CD%\!SQLITE_DIR! ^
  -DSQLITE3_LIBRARY=%CD%\!SQLITE_DIR!\sqlite3.lib 
if %errorlevel% neq 0 (
echo ERROR: PROJ configure failed
exit /b 1
)

echo === Building PROJ (super DLL) ===
cmake --build build_proj
if %errorlevel% neq 0 exit /b 1



echo ==== Instal PROJ ===============
cmake --install build_proj
if %errorlevel% neq 0 exit /b 1

echo ==== COPY z to PROJ install folder ===============
robocopy install_zlib\bin     install_proj\bin     z.dll
robocopy install_zlib\include install_proj\include *.h /S
robocopy install_zlib\lib     install_proj\lib     /E
robocopy install_zlib\share   install_proj\share   /E

@REM echo === Verifying dependencies of proj.dll ===
@REM if exist install_proj\bin\proj_9_3.dll (
@REM dumpbin /dependents install_proj\bin\proj_9_3.dll
@REM ) else (
@REM echo WARNING: proj.dll not found in expec

