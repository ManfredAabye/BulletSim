@echo off
setlocal EnableExtensions

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"
set "LOGDIR=%SCRIPT_DIR%\logs"
if not exist "%LOGDIR%\" mkdir "%LOGDIR%"
set "LOGFILE=%LOGDIR%\buildBulletSim.log"
echo === buildBulletSim started at %DATE% %TIME% > "%LOGFILE%"
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

set "VSWHERE=C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe"
for /f "usebackq delims=" %%M in (`"%VSWHERE%" -latest -requires Microsoft.Component.MSBuild -find MSBuild\**\Bin\MSBuild.exe 2^>nul`) do set "MSBUILD=%%M"
if not defined MSBUILD (
	echo ERROR: MSBuild.exe nicht gefunden. Bitte Visual Studio 2022 installieren.
	popd
	exit /b 1
)

set /p BULLETVERSION=<"lib\VERSION"
set /p BULLETSIMVERSION=<"VERSION"
set "CL=/D BULLETVERSION=%BULLETVERSION% /D BULLETSIMVERSION=%BULLETSIMVERSION%"

echo === Baue BulletSim.sln mit MSBuild ...
"%MSBUILD%" BulletSim.sln /p:Configuration=Release /p:Platform=x64 /m /nologo >> "%LOGFILE%" 2>&1
set "RC=%ERRORLEVEL%"
if %RC% EQU 0 (
	echo === buildBulletSim completed at %DATE% %TIME% >> "%LOGFILE%"
) else (
	echo === buildBulletSim failed with code %RC% at %DATE% %TIME% >> "%LOGFILE%"
)
echo === Log file: %LOGFILE%
popd
pause
exit /b %RC%
