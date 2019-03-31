@echo off

rem drop return variable
set "GENERATOR_IS_MULTI_CONFIG="

setlocal

set "CMAKE_GENERATOR=%~1"

if not defined CMAKE_GENERATOR (
  echo.%~nx0: error: CMAKE_GENERATOR is not defined.
  exit /b -126
) >&2

if not defined PROJECT_ROOT (
  echo.%~nx0: error: PROJECT_ROOT is not defined.
  exit /b -127
) >&2

rem create temporary directory
set "DATETIME_VALUE="
for /F "usebackq eol=	 tokens=1,2 delims==" %%i in (`wmic os get LocalDateTime /VALUE 2^>NUL`) do if "%%i" == "LocalDateTime" set "DATETIME_VALUE=%%j"

if not defined DATETIME_VALUE (
  echo.%~nx0: error: could not retrieve a date time value to create unique temporary directory.
  exit /b -128
) >&2

set "DATETIME_VALUE=%DATETIME_VALUE:~0,18%"

set "TEMP_DATE=%DATETIME_VALUE:~0,4%_%DATETIME_VALUE:~4,2%_%DATETIME_VALUE:~6,2%"
set "TEMP_TIME=%DATETIME_VALUE:~8,2%_%DATETIME_VALUE:~10,2%_%DATETIME_VALUE:~12,2%_%DATETIME_VALUE:~15,3%"

set "TEMP_OUTPUT_DIR=%TEMP%\%~n0.%TEMP_DATE%.%TEMP_TIME%"

rem create temporary files to store local context output
if exist "%TEMP_OUTPUT_DIR%\" (
  echo.%~nx0: error: temporary generated directory TEMP_OUTPUT_DIR is already exist: "%TEMP_OUTPUT_DIR%"
  exit /b -255
) >&2

mkdir "%TEMP_OUTPUT_DIR%"

rem drop rest variables
(
  endlocal
  set "TEMP_OUTPUT_DIR=%TEMP_OUTPUT_DIR:\=/%"
)

call :MAIN %%*
set LASTERROR=%ERRORLEVEL%

rem cleanup temporary files
rmdir /S /Q "%TEMP_OUTPUT_DIR%"

(
  set "LASTERROR="
  set "TEMP_OUTPUT_DIR="
  exit /b %LASTERROR%
)

:MAIN
rem arguments: <out_file_file>

call :CMD cmake -G "%%~1" "-DCMAKE_MODULE_PATH=%%PROJECT_ROOT%%/cmake" ^
  -P "%%PROJECT_ROOT%%/cmake/tools/GeneratorIsMulticonfig.cmd.cmake" ^
  --flock "%%TEMP_OUTPUT_DIR%%/lock" "%%TEMP_OUTPUT_DIR%%/var_values.lst" || exit /b

(
  echo.GENERATOR_IS_MULTI_CONFIG
) > "%TEMP_OUTPUT_DIR%/var_names.lst" || exit /b

call :CMD "%%PROJECT_ROOT%%/_scripts/tools/set_vars_from_locked_file_pair.bat" ^
  "%%TEMP_OUTPUT_DIR%%/lock" "%%TEMP_OUTPUT_DIR%%/var_names.lst" "%%TEMP_OUTPUT_DIR%%/var_values.lst" ^
  "%%PRINT_VARS_SET%%" || exit /b

exit /b 0

:CMD
if %TOOLS_VERBOSE%0 NEQ 0 (
  echo.^>^>%*
  echo.
)
(
  %*
)
exit /b
