@echo off

setlocal

set "?~0=%~0"
set "?~f0=%~f0"
set "?~dp0=%~dp0"
set "?~n0=%~n0"
set "?~nx0=%~nx0"
set "?~x0=%~x0"

call "%%~dp0__init__/__init__.bat" || exit /b

for %%i in (TACKLELIB_PROJECT_ROOT PROJECT_LOG_ROOT CONTOOLS_ROOT CONTOOLS_UTILITIES_BIN_ROOT) do (
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
  "%%CMAKE_CONFIG_VARS_SYSTEM_FILE_IN%%" "%%CMAKE_CONFIG_VARS_SYSTEM_FILE%%" ^
  "%%CMAKE_CONFIG_VARS_USER_FILE_IN%%" "%%CMAKE_CONFIG_VARS_USER_FILE%%" || exit /b

set /A NEST_LVL+=1

call :MAIN %%*
set LASTERROR=%ERRORLEVEL%

set /A NEST_LVL-=1

exit /b %LASTERROR%

:MAIN
rem CAUTION: an empty value and `*` value has different meanings!
rem
set "CMAKE_BUILD_TYPE=%~1"
set "CMAKE_BUILD_TARGET=%~2"

if not defined CMAKE_BUILD_TYPE (
  echo.%~nx0: error: CMAKE_BUILD_TYPE must be defined.
  exit /b 255
) >&2

rem CAUTION:
rem   This declares only most probable variant (guess) respective to the script extension.
rem   If not then the user have to explicitly pass the target name.
rem
if not defined CMAKE_BUILD_TARGET set "CMAKE_BUILD_TARGET=ALL_BUILD"

rem preload configuration files only to make some checks
call :CMD "%%CONTOOLS_ROOT%%/cmake/set_vars_from_files.bat" ^
  "%%CONFIG_VARS_SYSTEM_FILE:;=\;%%" "WIN" . . . ";" ^
  --exclude_vars_filter "PROJECT_ROOT" ^
  --ignore_late_expansion_statements || exit /b 1

rem check if selected generator is a multiconfig generator
call :CMD "%%CONTOOLS_ROOT%%/cmake/get_GENERATOR_IS_MULTI_CONFIG.bat" "%%CMAKE_GENERATOR%%" || exit /b 2

if "%CMAKE_BUILD_TYPE%" == "*" (
  for %%i in (%CMAKE_CONFIG_TYPES:;= %) do (
    set "CMAKE_BUILD_TYPE=%%i"
    call :BUILD %%* || exit /b
  )
) else (
  call :BUILD %%*
)

exit /b

:BUILD
if not defined CMAKE_BUILD_TYPE goto INIT2
if not defined CMAKE_CONFIG_ABBR_TYPES goto INIT2

call "%%CONTOOLS_ROOT%%/cmake/update_build_type.bat" || exit /b

:INIT2
if %GENERATOR_IS_MULTI_CONFIG%0 EQU 0 (
  call "%%CONTOOLS_ROOT%%/cmake/check_build_type.bat" ^
    "%%CMAKE_BUILD_TYPE%%" "%%CMAKE_CONFIG_TYPES%%" || exit /b
)

setlocal

rem load configuration files again unconditionally
set "CMAKE_BUILD_TYPE_ARG=%CMAKE_BUILD_TYPE%"
if not defined CMAKE_BUILD_TYPE_ARG set "CMAKE_BUILD_TYPE_ARG=."
rem escape all values for `--make_vars`
set "PROJECT_ROOT_ESCAPED=%PROJECT_ROOT:\=\\%"
set "PROJECT_ROOT_ESCAPED=%PROJECT_ROOT_ESCAPED:;=\;%"
call :CMD "%%CONTOOLS_ROOT%%/cmake/set_vars_from_files.bat" ^
  "%%CONFIG_VARS_SYSTEM_FILE:;=\;%%;%%CONFIG_VARS_USER_FILE:;=\;%%" "WIN" . "%%CMAKE_BUILD_TYPE_ARG%%" . ";" ^
  --make_vars ^
  "CMAKE_CURRENT_PACKAGE_NEST_LVL;CMAKE_CURRENT_PACKAGE_NEST_LVL_PREFIX;CMAKE_CURRENT_PACKAGE_NAME;CMAKE_CURRENT_PACKAGE_SOURCE_DIR;CMAKE_TOP_PACKAGE_NAME;CMAKE_TOP_PACKAGE_SOURCE_DIR" ^
  "0;00;%%PROJECT_NAME%%;%%PROJECT_ROOT_ESCAPED%%;%%PROJECT_NAME%%;%%PROJECT_ROOT_ESCAPED%%" ^
  --ignore_statement_if_no_filter --ignore_late_expansion_statements || exit /b

call "%%CONTOOLS_ROOT%%/cmake/make_output_directories.bat" "%%CMAKE_BUILD_TYPE%%" "%%GENERATOR_IS_MULTI_CONFIG%%" || exit /b

set "CMDLINE_FILE_IN=%PROJECT_ROOT%\_config\_build\04\%~nx0.in"

rem for safe parse
setlocal ENABLEDELAYEDEXPANSION

rem load command line from file
set "CMAKE_CMD_LINE="
for /F "usebackq eol=# tokens=* delims=" %%i in ("%CMDLINE_FILE_IN%") do (
  if defined CMAKE_CMD_LINE (
    set "CMAKE_CMD_LINE=!CMAKE_CMD_LINE! %%i"
  ) else (
    set "CMAKE_CMD_LINE=%%i"
  )
)

rem safe variable return over endlocal with delayed expansion
for /F "eol=# tokens=* delims=" %%i in ("!CMAKE_CMD_LINE!") do (
  endlocal
  set "CMAKE_CMD_LINE=%%i"
)

call :CMD pushd "%%CMAKE_BUILD_DIR%%" && (
  (
    call :CMD cmake %CMAKE_CMD_LINE% %%3 %%4 %%5 %%6 %%7 %%8 %%9
  ) || ( popd & goto BUILD_END )
  popd
)

:BUILD_END
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
