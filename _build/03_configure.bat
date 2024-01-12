@echo off

setlocal

if %IMPL_MODE%0 NEQ 0 goto IMPL

call "%%~dp0__init__/__init__.bat" || exit /b

call "%%TACKLELIB_PROJECT_ROOT%%/__init__/declare_builtins.bat" %%0 %%* || exit /b

for %%i in (TACKLELIB_PROJECT_ROOT PROJECT_LOG_ROOT CONTOOLS_ROOT CONTOOLS_UTILITIES_BIN_ROOT) do (
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

call "%%CONTOOLS_ROOT%%/std/get_cmdline.bat" %%?0%% %%*
call "%%CONTOOLS_ROOT%%/std/echo_var.bat" RETURN_VALUE ">"
echo.

call :CMDINT "%%CONTOOLS_ROOT%%/cmake/check_config_version.bat" ^
  "%%CMAKE_CONFIG_VARS_SYSTEM_FILE_IN%%" "%%CMAKE_CONFIG_VARS_SYSTEM_FILE%%" ^
  "%%CMAKE_CONFIG_VARS_USER_0_FILE_IN%%" "%%CMAKE_CONFIG_VARS_USER_0_FILE%%" || exit /b

set /A NEST_LVL+=1

call :MAIN %%*
set LASTERROR=%ERRORLEVEL%

set /A NEST_LVL-=1

exit /b %LASTERROR%

:MAIN
call "%%CONTOOLS_ROOT%%/cmake/parse_flags.bat" %%* || exit /b

if %__?FLAG_SHIFT% GTR 0 for /L %%i in (1,1,%__?FLAG_SHIFT%) do shift

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
call :CMD "%%CONTOOLS_ROOT%%/cmake/set_vars_from_files.bat" ^
  "%%CMAKE_CONFIG_VARS_SYSTEM_FILE:;=\;%%" "WIN" . . . ";" ^
  --exclude_vars_filter "TACKLELIB_PROJECT_ROOT" ^
  --ignore_late_expansion_statements || exit /b 255

rem check if selected generator is a multiconfig generator
call :CMD "%%CONTOOLS_ROOT%%/cmake/get_GENERATOR_IS_MULTI_CONFIG.bat" "%%CMAKE_GENERATOR%%" || exit /b 255

if %GENERATOR_IS_MULTI_CONFIG%0 NEQ 0 (
  rem CMAKE_CONFIG_TYPES must not be defined
  if %CMAKE_BUILD_TYPE_WITH_FORCE% NEQ 0 goto IGNORE_GENERATOR_IS_MULTI_CONFIG_CHECK

  if defined CMAKE_BUILD_TYPE (
    echo.%~nx0: error: declared cmake generator is a multiconfig generator, CMAKE_BUILD_TYPE must not be defined: CMAKE_GENERATOR="%CMAKE_GENERATOR%" CMAKE_BUILD_TYPE="%CMAKE_BUILD_TYPE%".
    exit /b 255
  ) >&2
) else (
  rem CMAKE_CONFIG_TYPES must be defined
  if not defined CMAKE_BUILD_TYPE (
    echo.%~nx0: error: declared cmake generator is not a multiconfig generator, CMAKE_BUILD_TYPE must be defined: CMAKE_GENERATOR="%CMAKE_GENERATOR%" CMAKE_BUILD_TYPE="%CMAKE_BUILD_TYPE%".
    exit /b 255
  ) >&2
  set CMAKE_IS_SINGLE_CONFIG=1
)

:IGNORE_GENERATOR_IS_MULTI_CONFIG_CHECK
if "%CMAKE_BUILD_TYPE%" == "*" (
  for %%i in (%CMAKE_CONFIG_TYPES:;= %) do (
    set "CMAKE_BUILD_TYPE=%%i"
    call :CONFIGURE %%2 %%3 %%4 %%5 %%6 %%7 %%8 %%9 || exit /b
  )
) else (
  call :CONFIGURE %%2 %%3 %%4 %%5 %%6 %%7 %%8 %%9
)

exit /b

:CONFIGURE
call :CONFIGURE_IMPL %%*
echo.
exit /b

:CONFIGURE_IMPL
if not defined CMAKE_BUILD_TYPE goto INIT2
if not defined CMAKE_CONFIG_ABBR_TYPES goto INIT2

call :CMD "%%CONTOOLS_ROOT%%/cmake/update_build_type.bat" "%%CMAKE_BUILD_TYPE%%" "%%CMAKE_CONFIG_ABBR_TYPES%%" "%%CMAKE_CONFIG_TYPES%%" || exit /b

:INIT2
if %CMAKE_IS_SINGLE_CONFIG%0 NEQ 0 (
  call :CMD "%%CONTOOLS_ROOT%%/cmake/check_build_type.bat" ^
    "%%CMAKE_BUILD_TYPE%%" "%%CMAKE_CONFIG_TYPES%%" || exit /b
)

setlocal

rem load configuration files again unconditionally
set "CMAKE_BUILD_TYPE_ARG=%CMAKE_BUILD_TYPE%"
if not defined CMAKE_BUILD_TYPE_ARG set "CMAKE_BUILD_TYPE_ARG=."
rem escape all values for `--make_vars`
set "PROJECT_ROOT_ESCAPED=%TACKLELIB_PROJECT_ROOT:\=/%"
set "PROJECT_ROOT_ESCAPED=%PROJECT_ROOT_ESCAPED:;=\;%"
call :CMD "%%CONTOOLS_ROOT%%/cmake/set_vars_from_files.bat" ^
  "%%CMAKE_CONFIG_VARS_SYSTEM_FILE:;=\;%%;%%CMAKE_CONFIG_VARS_USER_0_FILE:;=\;%%" "WIN" . "%%CMAKE_BUILD_TYPE_ARG%%" . ";" ^
  --make_vars ^
  "CMAKE_CURRENT_PACKAGE_NEST_LVL;CMAKE_CURRENT_PACKAGE_NEST_LVL_PREFIX;CMAKE_CURRENT_PACKAGE_NAME;CMAKE_CURRENT_PACKAGE_SOURCE_DIR;CMAKE_TOP_PACKAGE_NAME;CMAKE_TOP_PACKAGE_SOURCE_DIR" ^
  "0;00;%%PROJECT_NAME%%;%%PROJECT_ROOT_ESCAPED%%;%%PROJECT_NAME%%;%%PROJECT_ROOT_ESCAPED%%" ^
  --ignore_statement_if_no_filter --ignore_late_expansion_statements --ignore_unexisted_path_vars || exit /b

rem check if multiconfig.tag is already created
if exist "%CMAKE_BUILD_ROOT%/singleconfig.tag" (
  if %CMAKE_IS_SINGLE_CONFIG%0 EQU 0 (
    echo.%~nx0: error: single config cmake cache already has been created, can not continue with multi config: CMAKE_GENERATOR="%CMAKE_GENERATOR%" CMAKE_BUILD_TYPE="%CMAKE_BUILD_TYPE%".
    exit /b 255
  ) >&2
)

if exist "%CMAKE_BUILD_ROOT%/multiconfig.tag" (
  if %CMAKE_IS_SINGLE_CONFIG%0 NEQ 0 (
    echo.%~nx0: error: multi config cmake cache already has been created, can not continue with single config: CMAKE_GENERATOR="%CMAKE_GENERATOR%" CMAKE_BUILD_TYPE="%CMAKE_BUILD_TYPE%".
    exit /b 255
  ) >&2
)

if not exist "%CMAKE_BUILD_ROOT%\" mkdir "%CMAKE_BUILD_ROOT%"

if %CMAKE_IS_SINGLE_CONFIG%0 NEQ 0 (
  echo.> "%CMAKE_BUILD_ROOT%/singleconfig.tag"
  set "CMDLINE_FILE_IN=%TACKLELIB_PROJECT_INPUT_CONFIG_ROOT%\_build\%?~n0%\singleconfig\cmdline%?~x0%.in"
) else (
  echo.> "%CMAKE_BUILD_ROOT%/multiconfig.tag"
  set "CMDLINE_FILE_IN=%TACKLELIB_PROJECT_INPUT_CONFIG_ROOT%\_build\%?~n0%\multiconfig\cmdline%?~x0%.in"
)

call "%%CONTOOLS_ROOT%%/cmake/make_output_directories.bat" "%%CMAKE_BUILD_TYPE%%" "%%GENERATOR_IS_MULTI_CONFIG%%" || exit /b

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

:CMDINT
if %INIT_VERBOSE%0 NEQ 0 (
  echo.^>%*
  echo.
)
(
  %*
)
exit /b
