@echo off

setlocal

call "%%~dp0__init__/__init1__.bat" || exit /b

set /A NEST_LVL+=1


rem load configuration files
call :CMD "%%PROJECT_ROOT%%/_scripts/tools/set_vars_from_files.bat" ^
  "%%CONFIG_VARS_SYSTEM_FILE:;=\;%%" "WIN" . . . ";" ^
  --exclude_vars_filter "PROJECT_ROOT" ^
  --ignore_late_expansion_statements || goto EXIT

if defined CHCP chcp %CHCP%

pushd "%TESTS_ROOT%/01_unit" && (
  for %%i in (%PYTESTS_LIST%) do (
    call :CMD "%%PYTEST_EXE_PATH%%" %%* %%i || ( popd & goto EXIT )
  )
  popd
)

:EXIT
set LASTERROR=%ERRORLEVEL%

set /A NEST_LVL-=1

if %NEST_LVL%0 EQU 0 pause

exit /b %LASTERROR%

:CMD
echo.^>%*
(
  %*
)
exit /b
