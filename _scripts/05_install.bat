@echo off

setlocal

call "%%~dp0__init1__.bat" || goto INIT_EXIT

set /A NEST_LVL+=1


rem CAUTION: an empty value and `*` value has different meanings!
rem
set "CMAKE_BUILD_TYPE=%~1"
rem cmake install does not support particular target installation
set "CMAKE_BUILD_TARGET=INSTALL"

if not defined CMAKE_BUILD_TYPE (
  echo.%~nx0: error: CMAKE_BUILD_TYPE must be defined.
  call :EXIT_B 255
  goto EXIT
) >&2

rem preload configuration files only to make some checks
call :CMD "%%PROJECT_ROOT%%/_scripts/tools/set_vars_from_files.bat" ^
  "%%CONFIG_VARS_SYSTEM_FILE:;=\;%%" "WIN" . . . ";" ^
  --exclude_vars_filter "PROJECT_ROOT" ^
  --ignore_late_expansion_statements || goto EXIT

rem check if selected generator is a multiconfig generator
call :CMD "%%PROJECT_ROOT%%/_scripts/tools/get_GENERATOR_IS_MULTI_CONFIG.bat" "%%CMAKE_GENERATOR%%" || goto EXIT

if "%CMAKE_BUILD_TYPE%" == "*" (
  for %%i in (%CMAKE_CONFIG_TYPES:;= %) do (
    set "CMAKE_BUILD_TYPE=%%i"
    call :INSTALL || goto EXIT
  )
) else (
  call :INSTALL
)

goto EXIT

:INSTALL
if not defined CMAKE_BUILD_TYPE goto INIT2
if not defined CMAKE_CONFIG_ABBR_TYPES goto INIT2

call "%%PROJECT_ROOT%%/_scripts/tools/update_build_type.bat" || exit /b

:INIT2
if %GENERATOR_IS_MULTI_CONFIG%0 EQU 0 (
  call "%%PROJECT_ROOT%%/_scripts/tools/check_build_type.bat" ^
    "%%CMAKE_BUILD_TYPE%%" "%%CMAKE_CONFIG_TYPES%%" || exit /b
)

setlocal

rem load configuration files again unconditionally
set "CMAKE_BUILD_TYPE_ARG=%CMAKE_BUILD_TYPE%"
if not defined CMAKE_BUILD_TYPE_ARG set "CMAKE_BUILD_TYPE_ARG=."
call :CMD "%%PROJECT_ROOT%%/_scripts/tools/set_vars_from_files.bat" ^
  "%%CONFIG_VARS_SYSTEM_FILE:;=\;%%;%%CONFIG_VARS_USER_FILE:;=\;%%" "WIN" . "%%CMAKE_BUILD_TYPE_ARG%%" . ";" ^
  --make_vars ^
  "CMAKE_CURRENT_PACKAGE_NEST_LVL;CMAKE_CURRENT_PACKAGE_NEST_LVL_PREFIX;CMAKE_CURRENT_PACKAGE_NAME;CMAKE_CURRENT_PACKAGE_SOURCE_DIR;CMAKE_TOP_PACKAGE_NAME;CMAKE_TOP_PACKAGE_SOURCE_DIR" ^
  "0;00;%%PROJECT_NAME%%;%%PROJECT_ROOT:;=\;%%;%%PROJECT_NAME%%;%%PROJECT_ROOT:;=\;%%" ^
  --ignore_statement_if_no_filter --ignore_late_expansion_statements || exit /b

call "%%~dp0__init2__.bat" || exit /b

set "CMDLINE_FILE_IN=%PROJECT_ROOT%\config\_scripts\05\%~nx0.in"

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

pushd "%CMAKE_BUILD_DIR%" && (
  (
    call :CMD cmake %CMAKE_CMD_LINE%
  ) || ( popd & goto INSTALL_END )
  popd
)

:INSTALL_END
exit /b

:CMD
echo.^>%*
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
