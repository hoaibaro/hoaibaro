@echo off
setlocal enabledelayedexpansion

:: Set colors for output
for /f %%A in ('echo prompt $E ^| cmd') do set "ESC=%%A"
set "GREEN=%ESC%[32m"
set "RED=%ESC%[31m"
set "YELLOW=%ESC%[33m"
set "BLUE=%ESC%[34m"
set "RESET=%ESC%[0m"

title BAOPROVIP - Install Launcher

:: Step 1: Copy install.ps1
echo %BLUE%Step 1: Copying install.ps1 to Downloads folder...%RESET%
set "SOURCE_PATH=E:\LAB\CODING\baroTool\test_gui\install.ps1"
set "DEST_PATH=%USERPROFILE%\Downloads\"
set "DEST_FILE=%USERPROFILE%\Downloads\install.ps1"

echo Source: %SOURCE_PATH%
echo Destination: %DEST_PATH%
echo.

:: Check if source exists
if not exist "%SOURCE_PATH%" (
    echo %RED%ERROR: Source file not found at %SOURCE_PATH%%RESET%
    echo %RED%Please check if the file exists and try again.%RESET%
    echo.
    goto :error_exit
)

:: Create destination directory if not exists
if not exist "%DEST_PATH%" (
    echo Creating Downloads directory...
    mkdir "%DEST_PATH%" 2>nul
)

:: Copy file with verification
echo Copying file...
copy "%SOURCE_PATH%" "%DEST_PATH%" >nul 2>&1

if %errorlevel% equ 0 (
    echo %GREEN%SUCCESS: install.ps1 copied successfully!%RESET%
) else (
    echo %RED%ERROR: Failed to copy install.ps1%RESET%
    goto :error_exit
)

:: Verify file exists at destination
if not exist "%DEST_FILE%" (
    echo %RED%ERROR: File verification failed - install.ps1 not found at destination%RESET%
    goto :error_exit
)

:: Step 2: Change to destination directory
echo %BLUE%Step 2: Changing to Downloads directory...%RESET%
cd /d "%USERPROFILE%\Downloads"

if %errorlevel% neq 0 (
    echo %RED%ERROR: Failed to change to Downloads directory%RESET%
    goto :error_exit
)

echo Current directory: %CD%
echo.

:: Step 3: Execute PowerShell script
echo %BLUE%Step 3: Launching PowerShell script...%RESET%


@REM powershell -Command "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine -Force"
powershell -Command "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force"
powershell -ExecutionPolicy Bypass -WindowStyle Normal -File .\install.ps1 >nul 2>&1

set "PS_EXIT_CODE=%errorlevel%"

echo.

if %PS_EXIT_CODE% equ 0 (
    echo %GREEN%SUCCESS: Script execution completed successfully!%RESET%
) else (
    echo %YELLOW%WARNING: Script exited with code %PS_EXIT_CODE%%RESET%
)

echo.
echo %BLUE%Press any key to exit...%RESET%
exit /b %PS_EXIT_CODE%

:error_exit
echo.
echo %RED%Operation failed. Press any key to exit...%RESET%
pause >nul
exit /b 1
