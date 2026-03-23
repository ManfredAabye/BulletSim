@echo off
setlocal EnableExtensions

set "SCRIPT_DIR=%~dp0"
set "BULLETDIR=%BULLETDIR%"
if "%BULLETDIR%"=="" set "BULLETDIR=bullet3"

pushd "%SCRIPT_DIR%%BULLETDIR%\build3"
if errorlevel 1 (
	echo ERROR: could not enter "%SCRIPT_DIR%%BULLETDIR%\build3"
	exit /b 1
)

if not exist ".\premake4.exe" (
	echo ERROR: premake4.exe not found in %CD%
	popd
	exit /b 1
)

.\premake4.exe --no-clsocket --no-demos --no-enet --no-gtest --no-test --noopengl3 --os=windows --targetdir=../lib vs2010
set "RC=%ERRORLEVEL%"
popd
exit /b %RC%

