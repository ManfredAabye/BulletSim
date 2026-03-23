@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "SCRIPT_DIR=%~dp0"

if not defined BULLETMACH            set "BULLETMACH=x64"
if not defined BULLETDIR             set "BULLETDIR=bullet3"
if not defined DOTNET_REQUIRED_MAJOR set "DOTNET_REQUIRED_MAJOR=8"
if not defined BULLETCMAKE_GENERATOR set "BULLETCMAKE_GENERATOR=Visual Studio 17 2022"

where cmake  >nul 2>nul || ( echo ERROR: cmake was not found in PATH.  & exit /b 1 )
where dotnet >nul 2>nul || ( echo ERROR: dotnet was not found in PATH. & exit /b 1 )

for /f "tokens=1 delims=." %%A in ('dotnet --version 2^>nul') do set "DOTNET_MAJOR=%%A"
if not defined DOTNET_MAJOR (
    echo ERROR: could not determine dotnet version.
    exit /b 1
)
if %DOTNET_MAJOR% LSS %DOTNET_REQUIRED_MAJOR% (
    echo ERROR: dotnet SDK %DOTNET_REQUIRED_MAJOR%+ required.
    exit /b 1
)

set "BULLETROOT=%SCRIPT_DIR%%BULLETDIR%"
if not exist "%BULLETROOT%\" (
    echo ERROR: BULLETDIR not found: %BULLETROOT%
    exit /b 1
)
if not exist "%BULLETROOT%\VERSION" (
    echo ERROR: missing VERSION file in %BULLETROOT%
    exit /b 1
)
set /p BULLET_VERSION=<"%BULLETROOT%\VERSION"
for /f "tokens=1 delims=." %%A in ("%BULLET_VERSION%") do set "BULLET_MAJOR=%%A"
if not "%BULLET_MAJOR%"=="3" (
    echo ERROR: expected Bullet major version 3.x but found %BULLET_VERSION% in %BULLETDIR%
    exit /b 1
)
if defined BULLET_REQUIRED_VERSION if not "%BULLET_VERSION%"=="%BULLET_REQUIRED_VERSION%" (
    echo ERROR: expected Bullet version %BULLET_REQUIRED_VERSION% but found %BULLET_VERSION% in %BULLETDIR%
    exit /b 1
)

set "BUILDROOT=%BULLETROOT%\bullet-build"
if not exist "%BUILDROOT%\" mkdir "%BUILDROOT%"

echo === Building Bullet in dir %BULLETDIR% for arch %BULLETMACH% into bullet-build
pushd "%BUILDROOT%"

cmake -G "%BULLETCMAKE_GENERATOR%" -A %BULLETMACH% ^
    -DDOTNET_SDK=ON -DBUILD_BULLET3=ON -DBUILD_EXTRAS=ON ^
    -DBUILD_INVERSE_DYNAMIC_EXTRA=OFF -DBUILD_BULLET_ROBOTICS_GUI_EXTRA=OFF ^
    -DBUILD_BULLET_ROBOTICS_EXTRA=OFF -DBUILD_OBJ2SDF_EXTRA=OFF ^
    -DBUILD_SERIALIZE_EXTRA=OFF -DBUILD_CONVEX_DECOMPOSITION_EXTRA=ON ^
    -DBUILD_HACD_EXTRA=ON -DBUILD_GIMPACTUTILS_EXTRA=OFF ^
    -DBUILD_CPU_DEMOS=OFF ^
    -DBUILD_ENET=OFF -DBUILD_PYBULLET=OFF -DBUILD_UNIT_TESTS=OFF ^
    -DBUILD_SHARED_LIBS=OFF -DINSTALL_EXTRA_LIBS=ON -DINSTALL_LIBS=ON ^
    -DCMAKE_BUILD_TYPE=Release %BULLETCMAKE_ARGS% ..
if errorlevel 1 ( popd & exit /b 1 )

dotnet build BULLET_PHYSICS.sln -c Release -p:Configuration=Release
if errorlevel 1 ( popd & exit /b 1 )

popd

set "LIBDIR=%SCRIPT_DIR%lib"
set "INCDIR=%SCRIPT_DIR%include"
if not exist "%LIBDIR%\" mkdir "%LIBDIR%"
if not exist "%INCDIR%\" mkdir "%INCDIR%"

echo === Copy .lib files into the lib dir
for /r "%BUILDROOT%" %%f in (*.lib) do copy /y "%%f" "%LIBDIR%\" >nul

echo === Copy .h/.inl files into the include dir
if exist "%BULLETROOT%\src\" (
    robocopy "%BULLETROOT%\src" "%INCDIR%" *.h *.inl /S /E /NFL /NDL /NJH /NJS >nul
)

echo === Copy Extras .h/.inl files into the include dir
if exist "%BULLETROOT%\Extras\" (
    robocopy "%BULLETROOT%\Extras" "%INCDIR%" *.h *.inl /S /E /NFL /NDL /NJH /NJS >nul
)

if exist "%BULLETROOT%\VERSION" copy /y "%BULLETROOT%\VERSION" "%LIBDIR%\" >nul

exit /b 0

