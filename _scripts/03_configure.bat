@echo off

rem Configurator for cmake with generator.

setlocal

call "%%~dp0__init1__.bat" || goto INIT_EXIT

set /A NEST_LVL+=1


rem CAUTION: an empty value and `*` value has different meanings!
rem
set "CMAKE_BUILD_TYPE=%~1"

rem preload configuration files only to make some checks
call :CMD "%%PROJECT_ROOT%%/_scripts/tools/set_vars_from_files.bat" ^
  "%%CONFIG_VARS_SYSTEM_FILE:;=\;%%" "WIN" . . . ";" ^
  --exclude_vars_filter "PROJECT_ROOT" ^
  --ignore_late_expansion_statements || goto EXIT

rem check if selected generator is a multiconfig generator
call :CMD "%%PROJECT_ROOT%%/_scripts/tools/get_GENERATOR_IS_MULTI_CONFIG.bat" "%%CMAKE_GENERATOR%%" || goto EXIT

if %GENERATOR_IS_MULTI_CONFIG%0 NEQ 0 (
  rem CMAKE_CONFIG_TYPES must not be defined
  if defined CMAKE_BUILD_TYPE (
    echo.%~nx0: error: declared cmake generator is a multiconfig generator, CMAKE_BUILD_TYPE must not be defined: CMAKE_GENERATOR="%CMAKE_GENERATOR%" CMAKE_BUILD_TYPE="%CMAKE_BUILD_TYPE%".
    call :EXIT_B 127
    exit /b
  ) >&2
) else (
  rem CMAKE_CONFIG_TYPES must be defined
  if not defined CMAKE_BUILD_TYPE (
    echo.%~nx0: error: declared cmake generator is not a multiconfig generator, CMAKE_BUILD_TYPE must be defined: CMAKE_GENERATOR="%CMAKE_GENERATOR%" CMAKE_BUILD_TYPE="%CMAKE_BUILD_TYPE%".
    call :EXIT_B 128
    exit /b
  ) >&2
)

if "%CMAKE_BUILD_TYPE%" == "*" (
  for %%i in (%CMAKE_CONFIG_TYPES:;= %) do (
    set "CMAKE_BUILD_TYPE=%%i"
    call :CONFIGURE || goto EXIT
  )
) else (
  call :CONFIGURE
)

goto EXIT

:CONFIGURE
if not defined CMAKE_BUILD_TYPE goto INIT2
if not defined CMAKE_CONFIG_ABBR_TYPES goto INIT2

call "%%PROJECT_ROOT%%/_scripts/tools/update_build_type.bat" || exit /b

:INIT2
if %GENERATOR_IS_MULTI_CONFIG%0 EQU 0 (
  call :CMD "%%PROJECT_ROOT%%/_scripts/tools/check_build_type.bat" ^
    "%%CMAKE_BUILD_TYPE%%" "%%CMAKE_CONFIG_TYPES%%" || exit /b
)

setlocal

rem load configuration files again unconditionally
set "CMAKE_BUILD_TYPE_ARG=%CMAKE_BUILD_TYPE%"
if not defined CMAKE_BUILD_TYPE_ARG set "CMAKE_BUILD_TYPE_ARG=."
call :CMD "%%PROJECT_ROOT%%/_scripts/tools/set_vars_from_files.bat" ^
  "%%CONFIG_VARS_SYSTEM_FILE:;=\;%%;%%CONFIG_VARS_USER_FILE:;=\;%%" "WIN" . "%%CMAKE_BUILD_TYPE_ARG%%" . ";" ^
  --make_vars ^
  "CMAKE_CURRENT_PACKAGE_NEST_LVL;CMAKE_CURRENT_PACKAGE_NEST_LVL_PREFIX;CMAKE_CURRENT_PACKAGE_NAME;CMAKE_CURRENT_PACKAGE_SOURCE_DIR;CMAKE_TOP_PACKAGE_NAME;CMAKE_TOP_PACKAGE_NAME_SOURCE_DIR" ^
  "0;00;%%PROJECT_NAME%%;%%PROJECT_ROOT:;=\;%%;%%PROJECT_NAME%%;%%PROJECT_ROOT:;=\;%%" ^
  --ignore_statement_if_no_filter --ignore_late_expansion_statements || exit /b

call "%%~dp0__init2__.bat" || exit /b

set "CMDLINE_FILE_IN=%PROJECT_ROOT%\config\_scripts\03\%~nx0.in"

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

pushd "%CMAKE_BUILD_DIR%" && (
  (
    call :CMD cmake %CMAKE_CMD_LINE%
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

:EXIT_B
exit /b %~1

:EXIT
set /A NEST_LVL-=1

:INIT_EXIT
if %NEST_LVL%0 EQU 0 pause

exit /b
