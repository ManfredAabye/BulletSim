@echo off
setlocal EnableExtensions

set "SCRIPT_DIR=%~dp0"
pushd "%SCRIPT_DIR%"

if not exist "lib\VERSION" (
	echo ERROR: missing lib\VERSION. Build Bullet first ^(buildBulletCMake.*^).
	popd
	exit /b 1
)

if not exist "VERSION" (
	echo ERROR: missing VERSION.
	popd
	exit /b 1
)

for /f "tokens=1 delims=." %%A in ('dotnet --version 2^>nul') do set "DOTNET_MAJOR=%%A"
if not defined DOTNET_MAJOR (
	echo ERROR: dotnet was not found in PATH.
	popd
	exit /b 1
)

if %DOTNET_MAJOR% LSS 8 (
	echo ERROR: dotnet SDK 8+ required. Found major version %DOTNET_MAJOR%.
	popd
	exit /b 1
)

set /p BULLETVERSION=<"lib\VERSION"
set /p BULLETSIMVERSION=<"VERSION"
set "CL=/D BULLETVERSION=%BULLETVERSION% /D BULLETSIMVERSION=%BULLETSIMVERSION%"

dotnet build BulletSim.sln -c Release -p:Configuration=Release
set "RC=%ERRORLEVEL%"
popd
exit /b %RC%
