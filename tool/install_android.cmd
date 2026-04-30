@echo off
setlocal

set "ROOT=%~dp0.."
powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOT%\tool\install_android.ps1" %*
exit /b %ERRORLEVEL%
