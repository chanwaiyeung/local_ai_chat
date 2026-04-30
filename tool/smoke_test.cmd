@echo off
REM tool/smoke_test.cmd
REM
REM Universal Windows entry - works from cmd.exe or PowerShell.
REM Dispatches to smoke_test.ps1, which auto-starts the server, probes
REM /health /docs /query, and tears the server down on exit.

setlocal
set "SCRIPT_DIR=%~dp0"

where pwsh >nul 2>&1
if %errorlevel% equ 0 (
  pwsh -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%smoke_test.ps1" %*
) else (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%smoke_test.ps1" %*
)
exit /b %errorlevel%
