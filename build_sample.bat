@echo off
setlocal ENABLEDELAYEDEXPANSION

echo === Building sample app ===

echo === Configure sample app ===
cmake --fresh -S sample_app -B build_sample -G Ninja ^
  -DCMAKE_PREFIX_PATH=%CD%\install_proj ^
  -DCMAKE_BUILD_TYPE=Release ^
  -DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreadedDLL

if %errorlevel% neq 0 (
  echo ERROR: Sample app configure failed
  exit /b 1
)

echo === Build sample app ===
cmake --build build_sample

if %errorlevel% neq 0 (
  echo ERROR: Sample app build failed
  exit /b 1
)

echo === Install sample app ===
cmake --install build_sample --prefix install_sample

if %errorlevel% neq 0 (
  echo ERROR: Sample app install failed
  exit /b 1
)

echo === Test sample app ===
REM Copy PROJ DLL to sample app directory for testing
copy install_proj\bin\*.dll build_sample\ >nul 2>&1

REM Run the sample app
cd build_sample

proj_sample.exe

if %errorlevel% neq 0 (
  echo ERROR: Sample app test failed
  exit /b 1
)

REM Run the sample app

grid_transform.exe

if %errorlevel% neq 0 (
  echo ERROR: grid_transform app test failed
  exit /b 1
)

echo === Sample app build complete ===
