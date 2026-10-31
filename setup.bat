@echo off
color 0a
echo ===============================
echo  Funkin-Psych-Online Setup
echo ===============================
echo.

where haxelib >nul 2>nul
if errorlevel 1 (
    echo [ERROR] Haxe/haxelib not found in PATH. Install Haxe first: https://haxe.org/download/
    pause
    exit /b 1
)

echo Setting up haxelib repository...
haxelib setup

echo.
echo Installing hmm (Haxe Module Manager)...
haxelib install hmm
if errorlevel 1 (
    echo [ERROR] Failed to install hmm.
    pause
    exit /b 1
)

echo.
echo Installing project libraries from hmm.json...
haxelib run hmm install
if errorlevel 1 (
    echo [ERROR] hmm install failed.
    pause
    exit /b 1
)

echo.
echo All libraries installed successfully!
pause
