@echo off
cd /d "%~dp0"
if not exist "%TEMP%\BaroTool" mkdir "%TEMP%\BaroTool"
7z.exe x Setup.7z -o"%TEMP%\BaroTool" -y
cd /d "%TEMP%\BaroTool"
powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File install.ps1
