@echo off

setlocal

call "%%~dp0__init__/__init__.bat" || exit /b

call "%%TACKLELIB_PROJECT_ROOT%%/__init__/declare_builtins.bat" %%0 %%*

for %%i in (TESTS_PROJECT_ROOT PROJECT_LOG_ROOT CONTOOLS_ROOT CONTOOLS_UTILITIES_BIN_ROOT) do (
  if not defined %%i (
    echo.%~nx0: error: `%%i` variable is not defined.
    exit /b 255
  ) >&2
)

if %IMPL_MODE%0 NEQ 0 goto IMPL

call "%%CONTOOLS_ROOT%%/build/init_project_log.bat" "%%?~n0%%" || exit /b

"%CONTOOLS_UTILITIES_BIN_ROOT%/contools/callf.exe" ^
  /ret-child-exit /pause-on-exit /tee-stdout "%PROJECT_LOG_FILE%" /tee-stderr-dup 1 ^
  /v IMPL_MODE 1 /ra "%%" "%%?01%%" /v "?01" "%%" ^
  "${COMSPEC}" "/c \"@\"${?~f0}\" {*}\"" %* || exit /b

exit /b 0

:IMPL
call :CMDINT "%%CONTOOLS_ROOT%%/cmake/check_config_version.bat" ^
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
