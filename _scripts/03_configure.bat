@echo off

rem Configurator for cmake with generator.

setlocal

call "%%~dp0__init__/__init0__.bat" || goto INIT_EXIT

if %IMPL_MODE%0 NEQ 0 goto IMPL

rem no local logging if nested call
set WITH_LOGGING=0
if %NEST_LVL%0 EQU 0 set WITH_LOGGING=1

if %WITH_LOGGING% EQU 0 goto IMPL

if not exist "%SCRIPTS_LOGS_ROOT%\.log" mkdir "%SCRIPTS_LOGS_ROOT%\.log"

rem use stdout/stderr redirection with logging
call "%%CONTOOLS_ROOT%%\get_datetime.bat"
set "LOG_FILE_NAME_SUFFIX=%RETURN_VALUE:~0,4%'%RETURN_VALUE:~4,2%'%RETURN_VALUE:~6,2%_%RETURN_VALUE:~8,2%'%RETURN_VALUE:~10,2%'%RETURN_VALUE:~12,2%''%RETURN_VALUE:~15,3%"

set IMPL_MODE=1
rem CAUTION:
rem   We should avoid use handles 3 and 4 while the redirection has take a place because handles does reuse
rem   internally from left to right when being redirected externally.
rem   Example: if `1` is redirected, then `3` is internally reused, then if `2` redirected, then `4` is internally reused and so on.
rem   The discussion of the logic:
rem   https://stackoverflow.com/questions/9878007/why-doesnt-my-stderr-redirection-end-after-command-finishes-and-how-do-i-fix-i/9880156#9880156
rem   A partial analisis:
rem   https://www.dostips.com/forum/viewtopic.php?p=14612#p14612
rem
"%COMSPEC%" /C call %0 %* 2>&1 | "%CONTOOLS_ROOT%\tee.exe" "%SCRIPTS_LOGS_ROOT%\.log\%LOG_FILE_NAME_SUFFIX%.%~n0.log"
exit /b

:IMPL
call "%%~dp0__init__/__init1__.bat" || goto INIT_EXIT

set /A NEST_LVL+=1

call :MAIN %%*
set LASTERROR=%ERRORLEVEL%

set /A NEST_LVL-=1

if %NEST_LVL%0 EQU 0 call "%%CONTOOLS_ROOT%%/std/pause.bat"

exit /b %LASTERROR%

:MAIN
rem CAUTION: an empty value and `*` value has different meanings!
rem
set "CMAKE_BUILD_TYPE=%~1"
set "CMAKE_BUILD_TYPE_WITH_FORCE=0"

set CMAKE_IS_SINGLE_CONFIG=0

if not defined CMAKE_BUILD_TYPE goto IGNORE_CMAKE_BUILD_TYPE

if "%CMAKE_BUILD_TYPE%" == "%CMAKE_BUILD_TYPE:!=%" goto IGNORE_CMAKE_BUILD_TYPE

set "CMAKE_BUILD_TYPE=%CMAKE_BUILD_TYPE:!=%"
set CMAKE_BUILD_TYPE_WITH_FORCE=1
set CMAKE_IS_SINGLE_CONFIG=1

:IGNORE_CMAKE_BUILD_TYPE
rem preload configuration files only to make some checks
call :CMD "%%PROJECT_ROOT%%/_scripts/tools/set_vars_from_files.bat" ^
  "%%CONFIG_VARS_SYSTEM_FILE:;=\;%%" "WIN" . . . ";" ^
  --exclude_vars_filter "PROJECT_ROOT" ^
  --ignore_late_expansion_statements || exit /b 1

rem check if selected generator is a multiconfig generator
call :CMD "%%PROJECT_ROOT%%/_scripts/tools/get_GENERATOR_IS_MULTI_CONFIG.bat" "%%CMAKE_GENERATOR%%" || exit /b 2

if %GENERATOR_IS_MULTI_CONFIG%0 NEQ 0 (
  rem CMAKE_CONFIG_TYPES must not be defined
  if %CMAKE_BUILD_TYPE_WITH_FORCE% NEQ 0 goto IGNORE_GENERATOR_IS_MULTI_CONFIG_CHECK

  if defined CMAKE_BUILD_TYPE (
    echo.%~nx0: error: declared cmake generator is a multiconfig generator, CMAKE_BUILD_TYPE must not be defined: CMAKE_GENERATOR="%CMAKE_GENERATOR%" CMAKE_BUILD_TYPE="%CMAKE_BUILD_TYPE%".
    exit /b 127
  ) >&2
) else (
  rem CMAKE_CONFIG_TYPES must be defined
  if not defined CMAKE_BUILD_TYPE (
    echo.%~nx0: error: declared cmake generator is not a multiconfig generator, CMAKE_BUILD_TYPE must be defined: CMAKE_GENERATOR="%CMAKE_GENERATOR%" CMAKE_BUILD_TYPE="%CMAKE_BUILD_TYPE%".
    exit /b 128
  ) >&2
  set CMAKE_IS_SINGLE_CONFIG=1
)

:IGNORE_GENERATOR_IS_MULTI_CONFIG_CHECK
if "%CMAKE_BUILD_TYPE%" == "*" (
  for %%i in (%CMAKE_CONFIG_TYPES:;= %) do (
    set "CMAKE_BUILD_TYPE=%%i"
    call :CONFIGURE %%* || exit /b
  )
) else (
  call :CONFIGURE %%*
)

exit /b

:CONFIGURE
call :CONFIGURE_IMPL %%*
echo.
exit /b

:CONFIGURE_IMPL
if not defined CMAKE_BUILD_TYPE goto INIT2
if not defined CMAKE_CONFIG_ABBR_TYPES goto INIT2

call :CMD "%%PROJECT_ROOT%%/_scripts/tools/update_build_type.bat" || exit /b

:INIT2
if %CMAKE_IS_SINGLE_CONFIG%0 NEQ 0 (
  call :CMD "%%PROJECT_ROOT%%/_scripts/tools/check_build_type.bat" ^
    "%%CMAKE_BUILD_TYPE%%" "%%CMAKE_CONFIG_TYPES%%" || exit /b
)

setlocal

rem load configuration files again unconditionally
set "CMAKE_BUILD_TYPE_ARG=%CMAKE_BUILD_TYPE%"
if not defined CMAKE_BUILD_TYPE_ARG set "CMAKE_BUILD_TYPE_ARG=."
rem escape all values for `--make_vars`
set "PROJECT_ROOT_ESCAPED=%PROJECT_ROOT:\=\\%"
set "PROJECT_ROOT_ESCAPED=%PROJECT_ROOT_ESCAPED:;=\;%"
call :CMD "%%PROJECT_ROOT%%/_scripts/tools/set_vars_from_files.bat" ^
  "%%CONFIG_VARS_SYSTEM_FILE:;=\;%%;%%CONFIG_VARS_USER_FILE:;=\;%%" "WIN" . "%%CMAKE_BUILD_TYPE_ARG%%" . ";" ^
  --make_vars ^
  "CMAKE_CURRENT_PACKAGE_NEST_LVL;CMAKE_CURRENT_PACKAGE_NEST_LVL_PREFIX;CMAKE_CURRENT_PACKAGE_NAME;CMAKE_CURRENT_PACKAGE_SOURCE_DIR;CMAKE_TOP_PACKAGE_NAME;CMAKE_TOP_PACKAGE_SOURCE_DIR" ^
  "0;00;%%PROJECT_NAME%%;%%PROJECT_ROOT_ESCAPED%%;%%PROJECT_NAME%%;%%PROJECT_ROOT_ESCAPED%%" ^
  --ignore_statement_if_no_filter --ignore_late_expansion_statements || exit /b

rem check if multiconfig.tag is already created
if exist "%CMAKE_BUILD_ROOT%/singleconfig.tag" (
  if %CMAKE_IS_SINGLE_CONFIG%0 EQU 0 (
    echo.%~nx0: error: single config cmake cache already has been created, can not continue with multi config: CMAKE_GENERATOR="%CMAKE_GENERATOR%" CMAKE_BUILD_TYPE="%CMAKE_BUILD_TYPE%".
    exit /b 129
  ) >&2
)

if exist "%CMAKE_BUILD_ROOT%/multiconfig.tag" (
  if %CMAKE_IS_SINGLE_CONFIG%0 NEQ 0 (
    echo.%~nx0: error: multi config cmake cache already has been created, can not continue with single config: CMAKE_GENERATOR="%CMAKE_GENERATOR%" CMAKE_BUILD_TYPE="%CMAKE_BUILD_TYPE%".
    exit /b 130
  ) >&2
)

if not exist "%CMAKE_BUILD_ROOT%" mkdir "%CMAKE_BUILD_ROOT%"

if %CMAKE_IS_SINGLE_CONFIG%0 NEQ 0 (
  echo.> "%CMAKE_BUILD_ROOT%/singleconfig.tag"
  set "CMDLINE_FILE_IN=%PROJECT_ROOT%\_config\_scripts\03\singleconfig\%~nx0.in"
) else (
  echo.> "%CMAKE_BUILD_ROOT%/multiconfig.tag"
  set "CMDLINE_FILE_IN=%PROJECT_ROOT%\_config\_scripts\03\multiconfig\%~nx0.in"
)

call "%%~dp0__init__/__init2__.bat" || exit /b

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

if defined CMAKE_BUILD_TYPE (
  set CMAKE_CMD_LINE=!CMAKE_CMD_LINE! -D "CMAKE_BUILD_TYPE=!CMAKE_BUILD_TYPE!"
)
if defined CMAKE_MAKE_PROGRAM (
  set CMAKE_CMD_LINE=!CMAKE_CMD_LINE! -D "CMAKE_MAKE_PROGRAM=!CMAKE_MAKE_PROGRAM!"
)
if defined CMAKE_GENERATOR_TOOLSET (
  set CMAKE_CMD_LINE=!CMAKE_CMD_LINE! -T "!CMAKE_GENERATOR_TOOLSET!"
)
if defined CMAKE_GENERATOR_PLATFORM (
  set CMAKE_CMD_LINE=!CMAKE_CMD_LINE! -A "!CMAKE_GENERATOR_PLATFORM!"
)

rem safe variable return over endlocal with delayed expansion
for /F "eol=# tokens=* delims=" %%i in ("!CMAKE_CMD_LINE!") do (
  endlocal
  set "CMAKE_CMD_LINE=%%i"
)

call :CMD pushd "%%CMAKE_BUILD_DIR%%" && (
  (
    call :CMD cmake %CMAKE_CMD_LINE% %%2 %%3 %%4 %%5 %%6 %%7 %%8 %%9
  ) || ( popd & goto CONFIGURE_END )
  popd
)

:CONFIGURE_END
exit /b

:CMD
echo.^>%*
echo.
(
  %*
)
exit /b

:INIT_EXIT
set LASTERROR=%ERRORLEVEL%

if %NEST_LVL%0 EQU 0 call "%%CONTOOLS_ROOT%%/std/pause.bat"

exit /b %LASTERROR%
