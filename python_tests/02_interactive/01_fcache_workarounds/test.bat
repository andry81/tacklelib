@echo off

set "PYTHON_EXE_PATH=c:/Python/x86/38/python.exe"
set "TACKLELIB_ROOT=%~dp0..\..\..\python\tacklelib"
set "CMDOPLIB_ROOT=%~dp0..\..\..\python\cmdoplib"
set PYTHONDONTWRITEBYTECODE=1

start "" cmd.exe /k @"%PYTHON_EXE_PATH%" "%~dp0test_fcache.xpy" 111
rem start "" cmd.exe /k @"%PYTHON_EXE_PATH%" "%~dp0test_fcache.xpy" 222
rem start "" cmd.exe /k @"%PYTHON_EXE_PATH%" "%~dp0test_fcache.xpy" 333
rem start "" cmd.exe /k @"%PYTHON_EXE_PATH%" "%~dp0test_fcache.xpy" 444
rem start "" cmd.exe /k @"%PYTHON_EXE_PATH%" "%~dp0test_fcache.xpy" 555
