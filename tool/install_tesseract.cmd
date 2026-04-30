@echo off
REM tool/install_tesseract.cmd
REM
REM Universal Windows entry - dispatches to install_tesseract.ps1.

setlocal
set "SCRIPT_DIR=%~dp0"

where pwsh >nul 2>&1
if %errorlevel% equ 0 (
  pwsh -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%install_tesseract.ps1" %*
) else (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%install_tesseract.ps1" %*
)
exit /b %errorlevel%
