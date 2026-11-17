@echo off
rem Premisave launcher for Windows. Double click it, or run it from a terminal.
rem Passes every argument on to run.ps1, for example: run.bat -Platform windows
setlocal
where pwsh >NUL 2>NUL
if %errorlevel%==0 (
  pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0run.ps1" %*
) else (
  powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0run.ps1" %*
)
set RC=%errorlevel%
if "%~1"=="" if %RC% neq 0 pause
exit /b %RC%
