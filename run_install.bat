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

:: Step 1: Find the Setup folder
echo %BLUE%Step 1: Searching for the Setup folder...%RESET%

set "SOURCE_SETUP_DIR="

:: Search all drives for a folder named "Setup" that contains "install.ps1"
for %%d in (D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
    if exist "%%d:\" (
        for /f "delims=" %%f in ('dir /s /b "%%d:\Setup" 2^>nul') do (
            if exist "%%f\install.ps1" (
                set "SOURCE_SETUP_DIR=%%f"
                goto :FOUND_FOLDER
            )
        )
    )
)

:NOT_FOUND
echo %RED%Error: Could not find a 'Setup' folder containing 'install.ps1' on any drive.%RESET%
pause
exit /b 1

:FOUND_FOLDER
if "%SOURCE_SETUP_DIR%"=="" goto NOT_FOUND

echo %GREEN%Found Setup folder at: %SOURCE_SETUP_DIR%%RESET%
set "DEST_SETUP_DIR=%USERPROFILE%\Downloads\Setup"

echo Source:      %SOURCE_SETUP_DIR%
echo Destination: %DEST_SETUP_DIR%
echo.

:: Step 2: Copy the entire Setup folder, excluding the launcher itself
echo %BLUE%Step 2: Copying the Setup folder to Downloads...%RESET%

robocopy "%SOURCE_SETUP_DIR%" "%DEST_SETUP_DIR%" /E /XF "run_install.bat" >nul
if %errorlevel% geq 8 (
    echo %RED%ERROR: Failed to copy the Setup folder.%RESET%
    echo Robocopy exit code: %errorlevel%
    goto :error_exit
)

echo %GREEN%SUCCESS: Setup folder copied successfully!%RESET%

:: Verify that the destination script exists
if not exist "%DEST_SETUP_DIR%\install.ps1" (
    echo %RED%ERROR: File verification failed - install.ps1 not found at destination after copy.%RESET%
    goto :error_exit
)
echo.

:: Step 3: Change to destination directory
echo %BLUE%Step 3: Changing to the new Setup directory...%RESET%
cd /d "%DEST_SETUP_DIR%"

if %errorlevel% neq 0 (
    echo %RED%ERROR: Failed to change to the Setup directory in Downloads.%RESET%
    goto :error_exit
)

echo Current directory: %CD%
echo.

:: Step 4: Execute PowerShell script
echo %BLUE%Step 4: Launching PowerShell script...%RESET%

powershell -Command "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force" >nul
powershell -ExecutionPolicy Bypass -WindowStyle Normal -File .\install.ps1

set "PS_EXIT_CODE=%errorlevel%"

echo.

if %PS_EXIT_CODE% equ 1223 (
    echo %YELLOW%Operation canceled by user.%RESET%
) else if %PS_EXIT_CODE% equ 0 (
    echo %GREEN%SUCCESS: The installation script has been launched in a new window.%RESET%
) else (
    echo %RED%ERROR: The script failed to start. Exit code: %PS_EXIT_CODE%%RESET%
)

echo.
echo %BLUE%This window will close in 2 seconds...%RESET%
timeout /t 2 /nobreak >nul
exit /b %PS_EXIT_CODE%

:error_exit
echo.
echo %RED%Operation failed. This window will close in 2 seconds...%RESET%
timeout /t 2 /nobreak >nul
exit /b 1
