@echo off

set "PYTHON_EXE_PATH=c:/python/x86/38/python.exe"

call :CMD "%%PYTHON_EXE_PATH%%" -m pip install pip --upgrade || goto EXIT
call :CMD "%%PYTHON_EXE_PATH%%" -m pip install setuptools --upgrade || goto EXIT
call :CMD "%%PYTHON_EXE_PATH%%" -m pip install win_unicode_console --upgrade || goto EXIT
call :CMD "%%PYTHON_EXE_PATH%%" -m pip install prompt-toolkit --upgrade || goto EXIT
call :CMD "%%PYTHON_EXE_PATH%%" -m pip install xonsh --upgrade || goto EXIT
call :CMD "%%PYTHON_EXE_PATH%%" -m pip install plumbum --upgrade || goto EXIT
call :CMD "%%PYTHON_EXE_PATH%%" -m pip install pyyaml --upgrade || goto EXIT
call :CMD "%%PYTHON_EXE_PATH%%" -m pip install conditional --upgrade || goto EXIT
call :CMD "%%PYTHON_EXE_PATH%%" -m pip install pytest --upgrade || goto EXIT

:EXIT
set LASTERROR=%ERRORLEVEL%

pause

exit /b %LASTERROR%

:CMD
echo.^>%*
echo.
(
  %*
)
exit /b
