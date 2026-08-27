@echo off
setlocal
set "SD=%~dp0"
call "%SD%secret-tools.bat" %*
exit /b %errorlevel%
