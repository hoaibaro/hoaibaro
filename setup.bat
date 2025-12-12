@echo off
setlocal enabledelayedexpansion

:: Set colors for output
for /f %%A in ('echo prompt $E ^| cmd') do set "ESC=%%A"
set "GREEN=%ESC%[32m"
set "RED=%ESC%[31m"
set "BLUE=%ESC%[34m"
set "RESET=%ESC%[0m"

title BaroTool Installer Launcher

echo %BLUE%[1/3] Locating BaroTool.exe...%RESET%

:: Define paths
set "SCRIPT_DIR=%~dp0"
set "SOURCE_FILE=%SCRIPT_DIR%Setup\BaroTool.exe"
set "DEST_DIR=%USERPROFILE%\Downloads"
set "DEST_FILE=%DEST_DIR%\BaroTool.exe"

:: Check if source file exists
if not exist "%SOURCE_FILE%" (
    echo %RED%Error: BaroTool.exe not found at: %SOURCE_FILE%%RESET%
    echo %RED%Please ensure the 'Setup' folder is in the same directory as this script.%RESET%
    pause
    exit /b 1
)

echo %GREEN%Found source: %SOURCE_FILE%%RESET%

echo.
echo %BLUE%[2/3] Copying to Downloads...%RESET%

:: Create destination directory if needed
if not exist "%DEST_DIR%" mkdir "%DEST_DIR%"

:: Copy the file
copy /Y "%SOURCE_FILE%" "%DEST_FILE%" >nul
if %errorlevel% neq 0 (
    echo %RED%Error: Failed to copy file to %DEST_FILE%%RESET%
    pause
    exit /b 1
)

echo %GREEN%Copied to: %DEST_FILE%%RESET%

echo.
echo %BLUE%[3/3] Launching BaroTool...%RESET%

:: Execute the copied file
start "" "%DEST_FILE%"

echo %GREEN%Application launched successfully!%RESET%
echo.
echo Closing launcher in 3 seconds...
timeout /t 3 >nul
exit /b 0
