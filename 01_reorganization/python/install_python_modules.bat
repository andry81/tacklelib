@echo off

set "PYTHON_EXE_PATH=c:/python/x86/38/python.exe"

call :CMD "%%PYTHON_EXE_PATH%%" -m pip install pip --upgrade || goto EXIT
call :CMD "%%PYTHON_EXE_PATH%%" -m pip install setuptools --upgrade || goto EXIT
call :CMD "%%PYTHON_EXE_PATH%%" -m pip install win_unicode_console --upgrade
call :CMD "%%PYTHON_EXE_PATH%%" -m pip install prompt-toolkit --upgrade
call :CMD "%%PYTHON_EXE_PATH%%" -m pip install xonsh --upgrade
call :CMD "%%PYTHON_EXE_PATH%%" -m pip install plumbum --upgrade
call :CMD "%%PYTHON_EXE_PATH%%" -m pip install pyyaml --upgrade
call :CMD "%%PYTHON_EXE_PATH%%" -m pip install conditional --upgrade
call :CMD "%%PYTHON_EXE_PATH%%" -m pip install fcache --upgrade
call :CMD "%%PYTHON_EXE_PATH%%" -m pip install psutil --upgrade
call :CMD "%%PYTHON_EXE_PATH%%" -m pip install tzlocal --upgrade
call :CMD "%%PYTHON_EXE_PATH%%" -m pip install pytest --upgrade

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
