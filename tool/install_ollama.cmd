@echo off
REM tool/install_ollama.cmd
REM
REM Universal Windows entry - works from cmd.exe or PowerShell.
REM Dispatches to install_ollama.ps1.

setlocal
set "SCRIPT_DIR=%~dp0"

where pwsh >nul 2>&1
if %errorlevel% equ 0 (
  pwsh -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%install_ollama.ps1" %*
) else (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%install_ollama.ps1" %*
)
exit /b %errorlevel%
