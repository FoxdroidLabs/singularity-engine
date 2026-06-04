@echo off
setlocal enabledelayedexpansion

set APP_NAME=singularity-engine
set BINARY=singularity.exe
set ICON=singularity.png

echo.
echo   SINGULARITY ENGINE
echo   ------------------
echo   Installer v0.1
echo.
echo   Where do you want to install?
echo.
echo   [1] C:\Program Files\singularity-engine  (system)
echo   [2] %USERPROFILE%\AppData\Local\singularity-engine  (user)
echo   [3] Custom path
echo.
set /p choice=  Choice [1-3]: 

if "%choice%"=="1" set PREFIX=C:\Program Files\singularity-engine
if "%choice%"=="2" set PREFIX=%USERPROFILE%\AppData\Local\singularity-engine
if "%choice%"=="3" (
    set /p PREFIX=  Enter path: 
)

if not defined PREFIX (
    echo Invalid choice.
    exit /b 1
)

echo.
echo   Installing to %PREFIX%...

mkdir "%PREFIX%\engine\shaders" 2>nul
mkdir "%PREFIX%\engine\assets" 2>nul

copy "zig-out\bin\%BINARY%" "%PREFIX%\%BINARY%"
copy "zig-out\shaders\*.spv" "%PREFIX%\engine\shaders\"
copy "assets\%ICON%" "%PREFIX%\engine\assets\%ICON%"

:: Shortcut via PowerShell
set SHORTCUT=%USERPROFILE%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Singularity Engine.lnk
powershell -Command "$ws = New-Object -ComObject WScript.Shell; $s = $ws.CreateShortcut('%SHORTCUT%'); $s.TargetPath = '%PREFIX%\%BINARY%'; $s.IconLocation = '%PREFIX%\engine\assets\%ICON%'; $s.Save()"

echo.
echo   Done.
echo   Installed to : %PREFIX%
echo   Shortcut     : %SHORTCUT%
echo.
