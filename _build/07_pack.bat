@echo off

setlocal

call "%%~dp0__init__/script_init.bat" %%0 %%* || exit /b
if %IMPL_MODE%0 EQU 0 exit /b

call :CMDINT "%%CONTOOLS_ROOT%%/build/check_config_expiration.bat" ^
  -- "%%CMAKE_CONFIG_VARS_SYSTEM_FILE_IN%%" "%%CMAKE_CONFIG_VARS_SYSTEM_FILE%%" || exit /b

call :CMDINT "%%CONTOOLS_ROOT%%/build/check_config_expiration.bat" ^
  -- "%%CMAKE_CONFIG_VARS_USER_0_FILE_IN%%" "%%CMAKE_CONFIG_VARS_USER_0_FILE%%" || exit /b

set /A NEST_LVL+=1

call :MAIN %%*
set LASTERROR=%ERRORLEVEL%

set /A NEST_LVL-=1

exit /b %LASTERROR%

:MAIN
rem CAUTION: an empty value and `*` value has different meanings!
rem
set "CMAKE_BUILD_TYPE=%~1"
rem cmake pack does not support particular target enpackage
set "CMAKE_BUILD_TARGET=BUNDLE"

set FLAG_SHIFT=1

if not defined CMAKE_BUILD_TYPE (
  echo.%?~nx0%: error: CMAKE_BUILD_TYPE must be defined.
  exit /b 255
) >&2

rem preload configuration files only to make some checks
call :CMD "%%CONTOOLS_ROOT%%/std/set_vars_from_files.bat" ^
  "%%CMAKE_CONFIG_VARS_SYSTEM_FILE:;=\;%%" "WIN" . . . ";" ^
  --exclude_vars_filter "PROJECT_ROOT" ^
  --ignore_late_expansion_statements || exit /b 255

rem check if selected generator is a multiconfig generator
call :CMD "%%CONTOOLS_ROOT%%/cmake/get_GENERATOR_IS_MULTI_CONFIG.bat" "%%CMAKE_GENERATOR%%" || exit /b 255

if "%CMAKE_BUILD_TYPE%" == "*" (
  for %%i in (%CMAKE_CONFIG_TYPES:;= %) do (
    set "CMAKE_BUILD_TYPE=%%i"
    call :PACK || exit /b
  )
) else (
  call :PACK
)

exit /b

:PACK
if not defined CMAKE_BUILD_TYPE goto INIT2
if not defined CMAKE_CONFIG_ABBR_TYPES goto INIT2

call "%%CONTOOLS_ROOT%%/cmake/update_build_type.bat" "%%CMAKE_BUILD_TYPE%%" "%%CMAKE_CONFIG_ABBR_TYPES%%" "%%CMAKE_CONFIG_TYPES%%" || exit /b

:INIT2
if %GENERATOR_IS_MULTI_CONFIG%0 EQU 0 (
  call "%%CONTOOLS_ROOT%%/cmake/check_build_type.bat" "%%CMAKE_BUILD_TYPE%%" "%%CMAKE_CONFIG_TYPES%%" || exit /b
)

setlocal

rem load configuration files again unconditionally
set "CMAKE_BUILD_TYPE_ARG=%CMAKE_BUILD_TYPE%"
if not defined CMAKE_BUILD_TYPE_ARG set "CMAKE_BUILD_TYPE_ARG=."
rem escape all values for `--make_vars`
set "PROJECT_ROOT_ESCAPED=%PROJECT_ROOT:\=/%"
set "PROJECT_ROOT_ESCAPED=%PROJECT_ROOT_ESCAPED:;=\;%"
call :CMD "%%CONTOOLS_ROOT%%/cmake/set_vars_from_files.bat" ^
  "%%CMAKE_CONFIG_VARS_SYSTEM_FILE:;=\;%%;%%CMAKE_CONFIG_VARS_USER_0_FILE:;=\;%%" "WIN" . "%%CMAKE_BUILD_TYPE_ARG%%" . ";" ^
  --make_vars ^
  "CMAKE_CURRENT_PACKAGE_NEST_LVL;CMAKE_CURRENT_PACKAGE_NEST_LVL_PREFIX;CMAKE_CURRENT_PACKAGE_NAME;CMAKE_CURRENT_PACKAGE_SOURCE_DIR;CMAKE_TOP_PACKAGE_NAME;CMAKE_TOP_PACKAGE_SOURCE_DIR" ^
  "0;00;%%PROJECT_NAME%%;%%PROJECT_ROOT_ESCAPED%%;%%PROJECT_NAME%%;%%PROJECT_ROOT_ESCAPED%%" ^
  --ignore_statement_if_no_filter --ignore_late_expansion_statements || exit /b

call "%%CONTOOLS_ROOT%%/cmake/make_output_directories.bat" "%%CMAKE_BUILD_TYPE%%" "%%GENERATOR_IS_MULTI_CONFIG%%" || exit /b

if not exist "%NSIS_INSTALL_ROOT%" (
  echo.%?~nx0%: error: NSIS_INSTALL_ROOT directory does not exist: `%NSIS_INSTALL_ROOT%`.
  exit /b 255
) >&2

set "PATH=%PATH%;%NSIS_INSTALL_ROOT%"

set "CMDLINE_FILE_IN=%TACKLELIB_PROJECT_INPUT_CONFIG_ROOT%\_build\%?~n0%\cmdline%?~x0%.in"

rem load command line from file
call "%%CONTOOLS_ROOT%%/build/load_cmdline.bat" CMAKE_CMD_LINE "%%CMDLINE_FILE_IN%%"

call :CMD pushd "%%CMAKE_BUILD_DIR%%" && (
  call :CMD cmake %%CMAKE_CMD_LINE%% %%SCRIPT_CMD_LINE%% || ( popd & goto PACK_END )
  popd
)

:PACK_END
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
