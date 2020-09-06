@echo off

set "PYTHON_EXE_PATH=c:/Python/x86/38/python.exe"
set TERMINAL_CMD=start "" cmd.exe /k @
set "TACKLELIB_ROOT=%~dp0..\..\..\python\tacklelib"
set "CMDOPLIB_ROOT=%~dp0..\..\..\python\cmdoplib"
set PYTHONDONTWRITEBYTECODE=1

%TERMINAL_CMD%"%PYTHON_EXE_PATH%" "%~dp0test_fcache.xpy" 111
%TERMINAL_CMD%"%PYTHON_EXE_PATH%" "%~dp0test_fcache.xpy" 222
%TERMINAL_CMD%"%PYTHON_EXE_PATH%" "%~dp0test_fcache.xpy" 333
%TERMINAL_CMD%"%PYTHON_EXE_PATH%" "%~dp0test_fcache.xpy" 444
%TERMINAL_CMD%"%PYTHON_EXE_PATH%" "%~dp0test_fcache.xpy" 555
