@echo off
setlocal EnableExtensions

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

set /a REMOVED=0

echo === Cleaning BulletSim build artifacts in "%SCRIPT_DIR%"

call :RemoveDir "%SCRIPT_DIR%\bullet3\bullet-build"
call :RemoveDir "%SCRIPT_DIR%\bullet3"
call :RemoveDir "%SCRIPT_DIR%\lib"
call :RemoveDir "%SCRIPT_DIR%\include"
call :RemoveDir "%SCRIPT_DIR%\logs"
call :RemoveDir "%SCRIPT_DIR%\x64"

call :RemoveFile "%SCRIPT_DIR%\logsbuildBulletCMake.log"
call :RemoveFile "%SCRIPT_DIR%\BulletSimVersionInfo"

call :DeletePattern "%SCRIPT_DIR%" "libBulletSim-*.so"
call :DeletePattern "%SCRIPT_DIR%" "libBulletSim-*.dylib"
call :DeletePattern "%SCRIPT_DIR%" "BulletSim.dll"
call :DeletePattern "%SCRIPT_DIR%" "BulletSim.lib"
call :DeletePattern "%SCRIPT_DIR%" "BulletSim.pdb"

echo === Cleanup done. Removed items: %REMOVED%
exit /b 0

:RemoveDir
if exist "%~1\" (
	echo [DIR ] %~1
	rmdir /s /q "%~1"
	set /a REMOVED+=1
)
exit /b 0

:RemoveFile
if exist "%~1" (
	echo [FILE] %~1
	del /q "%~1"
	set /a REMOVED+=1
)
exit /b 0

:DeletePattern
set "TARGET_DIR=%~1"
set "TARGET_PATTERN=%~2"
for %%F in ("%TARGET_DIR%\%TARGET_PATTERN%") do (
	if exist "%%~fF" (
		echo [FILE] %%~fF
		del /q "%%~fF"
		set /a REMOVED+=1
	)
)
exit /b 0
