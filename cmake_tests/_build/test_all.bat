@echo off

setlocal

set "?~0=%~0"
set "?~f0=%~f0"
set "?~dp0=%~dp0"
set "?~n0=%~n0"
set "?~nx0=%~nx0"
set "?~x0=%~x0"

call "%%~dp0__init__/__init__.bat" || exit /b

for %%i in (TESTS_PROJECT_ROOT PROJECT_LOG_ROOT CONTOOLS_ROOT CONTOOLS_UTILITIES_BIN_ROOT) do (
  if not defined %%i (
    echo.%~nx0: error: `%%i` variable is not defined.
    exit /b 255
  ) >&2
)

if %IMPL_MODE%0 NEQ 0 goto IMPL

rem use stdout/stderr redirection with logging
call "%%CONTOOLS_ROOT%%\wmi\get_wmic_local_datetime.bat"
set "PROJECT_LOG_FILE_NAME_SUFFIX=%RETURN_VALUE:~0,4%'%RETURN_VALUE:~4,2%'%RETURN_VALUE:~6,2%_%RETURN_VALUE:~8,2%'%RETURN_VALUE:~10,2%'%RETURN_VALUE:~12,2%''%RETURN_VALUE:~15,3%"

set "PROJECT_LOG_DIR=%PROJECT_LOG_ROOT%\%PROJECT_LOG_FILE_NAME_SUFFIX%.%?~n0%"
set "PROJECT_LOG_FILE=%PROJECT_LOG_DIR%\%PROJECT_LOG_FILE_NAME_SUFFIX%.%?~n0%.log"

if not exist "%PROJECT_LOG_DIR%" ( mkdir "%PROJECT_LOG_DIR%" || exit /b )

set ?__CMDLINE__=%*
"%CONTOOLS_UTILITIES_BIN_ROOT%/contools/callf.exe" ^
  /ret-child-exit /pause-on-exit /tee-stdout "%PROJECT_LOG_FILE%" /tee-stderr-dup 1 ^
  /v IMPL_MODE 1 /ra "%%" "%%?01%%" /v "?01" "%%" ^
  /E0 /S1 /E2 /E3 ^
  "${COMSPEC}" "/c \"@\"{0}\" {1}\"" "${?~f0}" "${?__CMDLINE__}"
exit /b

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
  "-DCMAKE_MODULE_PATH=%%TESTS_PROJECT_ROOT:\=/%%;%%TACKLELIB_CMAKE_ROOT:\=/%%" ^
  "-DTESTS_PROJECT_ROOT=%%TESTS_PROJECT_ROOT:\=/%%" ^
  "-DTESTS_PROJECT_OUTPUT_CONFIG_ROOT=%%TESTS_PROJECT_OUTPUT_CONFIG_ROOT:\=/%%" ^
  "-DTACKLELIB_TESTLIB_TESTSCRIPT_FILE=%%TESTS_PROJECT_ROOT:\=/%%/%%?~n0%%.cmake" ^
  "-DTACKLELIB_TESTLIB_ROOT=%%TACKLELIB_CMAKE_ROOT:\=/%%/tacklelib/testlib" ^
  -P ^
  "%%TACKLELIB_CMAKE_ROOT:\=/%%/tacklelib/testlib/tools/RunTestLib.cmake" ^
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
