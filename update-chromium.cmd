@echo off
setlocal
set MSYS_HOME=C:\MinGW\msys\1.0
set BASE_DIR=%~dp0
"%MSYS_HOME%"\bin\sh.exe "%BASE_DIR%"update.sh
endlocal