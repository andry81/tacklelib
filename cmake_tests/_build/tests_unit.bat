@echo off

setlocal

if %IMPL_MODE%0 NEQ 0 goto IMPL

call "%%~dp0__init__/__init__.bat" || exit /b

call "%%TACKLELIB_PROJECT_ROOT%%/__init__/declare_builtins.bat" %%0 %%* || exit /b

for %%i in (TESTS_PROJECT_ROOT PROJECT_LOG_ROOT CONTOOLS_ROOT CONTOOLS_UTILITIES_BIN_ROOT) do (
  if not defined %%i (
    echo.%~nx0: error: `%%i` variable is not defined.
    exit /b 255
  ) >&2
)

call "%%CONTOOLS_ROOT%%/build/init_project_log.bat" "%%?~n0%%" || exit /b

call "%%CONTOOLS_ROOT%%/exec/exec_callf_prefix.bat" -- %%* || exit /b

exit /b 0

:IMPL
rem CAUTION: We must to reinit the builtin variables in case if `IMPL_MODE` was already setup outside.
call "%%CONTOOLS_ROOT%%/std/declare_builtins.bat" %%0 %%* || exit /b

call :CMDINT "%%CONTOOLS_ROOT%%/build/check_config_expiration.bat" ^
  "%%CMAKE_CONFIG_VARS_SYSTEM_FILE_IN%%" "%%CMAKE_CONFIG_VARS_SYSTEM_FILE%%" || exit /b

set /A NEST_LVL+=1

call :MAIN %%*
set LASTERROR=%ERRORLEVEL%

set /A NEST_LVL-=1

exit /b %LASTERROR%

:MAIN
call :CMD cmake ^
  "-DCMAKE_MODULE_PATH=%%TESTS_PROJECT_ROOT%%;%%TACKLELIB_CMAKE_ROOT%%" ^
  "-DTESTS_PROJECT_ROOT=%%TESTS_PROJECT_ROOT%%" ^
  "-DTESTS_PROJECT_OUTPUT_CONFIG_ROOT=%%TESTS_PROJECT_OUTPUT_CONFIG_ROOT:\=/%%" ^
  "-DTACKLELIB_TESTLIB_TESTSCRIPT_FILE=%%TESTS_PROJECT_ROOT%%/%%?~n0%%.cmake" ^
  "-DTACKLELIB_TESTLIB_ROOT=%%TACKLELIB_CMAKE_ROOT%%/tacklelib/testlib" ^
  -P ^
  "%%TACKLELIB_CMAKE_ROOT%%/tacklelib/testlib/tools/RunTestLib.cmake" ^
  %%* || exit /b

:TEST_END
exit /b

:CMD
echo.^>%*
echo.
(
  %*
)
exit /b

:CMDINT
if %INIT_VERBOSE%0 NEQ 0 (
  echo.^>%*
  echo.
)
(
  %*
)
exit /b
