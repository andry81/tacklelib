@echo off

setlocal

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
setlocal
call :SET_FLAGS %%*

(
  endlocal
  call :MAIN_IMPL ^
    %__SET_VARS_FROM_FILES_FLAGS__% ^
    --flock "%%TEMP_OUTPUT_DIR%%/lock" --vars "%%TEMP_OUTPUT_DIR%%/var_names.lst" --values "%%TEMP_OUTPUT_DIR%%/var_values.lst" ^
    "%%~1" "%%~2" "%%~3" "%%~4" "%%~5" "%%~6"
)

exit /b

:SET_FLAGS
set "__SET_VARS_FROM_FILES_FLAGS__="

shift
shift
shift
shift
shift
shift

:FLAGS_LOOP
set "__FLAGS__=%~1"

if not defined __FLAGS__ goto FLAGS_LOOP_END

rem safe set call
setlocal ENABLEDELAYEDEXPANSION
if defined __SET_VARS_FROM_FILES_FLAGS__ (
  for /F "eol=	 tokens=1,* delims=|" %%i in ("!__SET_VARS_FROM_FILES_FLAGS__!|!__FLAGS__!") do (
    endlocal
    set __SET_VARS_FROM_FILES_FLAGS__=%%i "%%j"
  )
) else for /F "eol=	 tokens=* delims=" %%i in ("!__FLAGS__!") do (
  endlocal
  set __SET_VARS_FROM_FILES_FLAGS__="%%i"
)

shift

goto FLAGS_LOOP

:FLAGS_LOOP_END

if defined __SET_VARS_FROM_FILES_FLAGS__ (
  setlocal ENABLEDELAYEDEXPANSION
  for /F "eol=	 tokens=* delims=" %%i in ("!__SET_VARS_FROM_FILES_FLAGS__:%%=%%%%!") do (
    endlocal
    set "__SET_VARS_FROM_FILES_FLAGS__=%%i"
  )
)

rem safe set call
setlocal ENABLEDELAYEDEXPANSION
for /F "eol=	 tokens=* delims=" %%i in ("!__SET_VARS_FROM_FILES_FLAGS__!") do (
  endlocal
  set "__SET_VARS_FROM_FILES_FLAGS__=%%i"
)

exit /b 0

:MAIN_IMPL
rem arguments: <flag0>[...<flagN>] "<file0>[...\;<fileN>]" <os_name> <compiler_name> <config_name> <arch_name> <list_separator_char>

call :CMD cmake "-DCMAKE_MODULE_PATH=%%PROJECT_ROOT%%/cmake" ^
  -P "%%PROJECT_ROOT%%/cmake/tacklelib/tools/SetVarsFromFiles.cmd.cmake" %%* || exit /b

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
