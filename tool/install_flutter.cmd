@echo off
REM tool/install_flutter.cmd
REM
REM Universal Windows entry point ? works from cmd.exe or PowerShell, no bash
REM needed. Just dispatches to install_flutter.ps1 with sane PowerShell flags.
REM
REM Usage from anywhere:
REM   tool\install_flutter.cmd
REM   "C:\path\to\project\tool\install_flutter.cmd"

setlocal
set "SCRIPT_DIR=%~dp0"

where pwsh >nul 2>&1
if %errorlevel% equ 0 (
  pwsh -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%install_flutter.ps1" %*
) else (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%install_flutter.ps1" %*
)
exit /b %errorlevel%
