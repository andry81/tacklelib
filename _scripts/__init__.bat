@echo off

rem CAUTION:
rem  In case of usage the QtCreator there is set of special broken cases you have to avoid:
rem  1. Invalid characters in paths: `(`, `)` and `.`.
rem  2. Non english locale in paths.

rem execution guard
if defined __INIT__ exit /b 0

call :CANONICAL_PATH "%%~dp0.."
set "PROJECT_ROOT=%PATH_VALUE%"

set "CONFIGURE_VARS_FILE_IN=%PROJECT_ROOT%/environment_local.vars.in"
set "CONFIGURE_VARS_FILE=%PROJECT_ROOT%/environment_local.vars"
set "CONFIGURE_CMAKE_FILE_IN=%PROJECT_ROOT%/environment_local.cmake.in"
set "CONFIGURE_CMAKE_FILE=%PROJECT_ROOT%/environment_local.cmake"

if not exist "%CONFIGURE_VARS_FILE%" goto CONFIGURE_VARS_FILE_NOT_EXISTS

rem Test input and output files on version equality, otherwise we must stop and warn the user to merge the changes by yourself!
set /P CONFIGURE_VARS_FILE_IN_VER_LINE=<"%CONFIGURE_VARS_FILE_IN%"
set /P CONFIGURE_VARS_FILE_VER_LINE=<"%CONFIGURE_VARS_FILE%"

if /i "%CONFIGURE_VARS_FILE_IN_VER_LINE:~0,12%" == "#%%%% version:" (
  if not "%CONFIGURE_VARS_FILE_IN_VER_LINE:~13%" == "%CONFIGURE_VARS_FILE_VER_LINE:~13%" (
    echo. %~nx0: error: version of "%CONFIGURE_VARS_FILE_IN%" is not equal to version of "%CONFIGURE_VARS_FILE%", use must merge changes by yourself!
    goto EXIT_WITH_ERROR
  ) >&2
)

:CONFIGURE_VARS_FILE_NOT_EXISTS

if not exist "%CONFIGURE_CMAKE_FILE%" goto CONFIGURE_CMAKE_FILE_NOT_EXISTS

rem Test input and output files on version equality, otherwise we must stop and warn the user to merge the changes by yourself!
set /P CONFIGURE_CMAKE_FILE_IN_VER_LINE=<"%CONFIGURE_CMAKE_FILE_IN%"
set /P CONFIGURE_CMAKE_FILE_VER_LINE=<"%CONFIGURE_CMAKE_FILE%"

if /i "%CONFIGURE_CMAKE_FILE_IN_VER_LINE:~0,12%" == "#%%%% version:" (
  if not "%CONFIGURE_CMAKE_FILE_IN_VER_LINE:~13%" == "%CONFIGURE_CMAKE_FILE_VER_LINE:~13%" (
    echo. %~nx0: error: version of "%CONFIGURE_CMAKE_FILE_IN%" is not equal to version of "%CONFIGURE_CMAKE_FILE%", use must merge changes by yourself!
    goto EXIT_WITH_ERROR
  ) >&2
)

:CONFIGURE_CMAKE_FILE_NOT_EXISTS

if not exist "%CONFIGURE_VARS_FILE%" (
  type "%CONFIGURE_VARS_FILE_IN:/=\%"
) > "%CONFIGURE_VARS_FILE%"

rem load external variables from file
set "CMAKE_CMD_LINE="
for /F "usebackq eol=# tokens=1,* delims==" %%i in ("%CONFIGURE_VARS_FILE%") do (
  if not "%%i" == "" (
    if not "%%j" == "" (
      call :CMD set "%%i=%%j"
    ) else (
      call :CMD set "%%i="
    )
  )
)

rem builtin variables
set "CMAKE_OUTPUT_ROOT=%PROJECT_ROOT%/_out"

set "CMAKE_BUILD_ROOT=%CMAKE_OUTPUT_ROOT%/build"
set "CMAKE_BIN_ROOT=%CMAKE_OUTPUT_ROOT%/bin"
set "CMAKE_LIB_ROOT=%CMAKE_OUTPUT_ROOT%/lib"
set "CMAKE_INSTALL_ROOT=%CMAKE_OUTPUT_ROOT%/install"
set "CMAKE_CPACK_ROOT=%CMAKE_OUTPUT_ROOT%/pack"

set "CMAKE_GENERATOR_TOOLSET=%CMAKE_GENERATOR_WINBAT_TOOLSET%"

if not defined NEST_LVL set NEST_LVL=0

if not exist "%CMAKE_BUILD_ROOT%\" call :CMD mkdir "%%CMAKE_BUILD_ROOT%%"
if not exist "%CMAKE_BIN_ROOT%\" call :CMD mkdir "%%CMAKE_BIN_ROOT%%"
if not exist "%CMAKE_LIB_ROOT%\" call :CMD mkdir "%%CMAKE_LIB_ROOT%%"
if not exist "%CMAKE_CPACK_ROOT%\" call :CMD mkdir "%%CMAKE_CPACK_ROOT%%"

exit /b 0

:CANONICAL_PATH
set "PATH_VALUE=%~dpf1"
set "PATH_VALUE=%PATH_VALUE:\=/%"
exit /b 0

:CMD
echo.^>%*
(
  %*
)
exit /b

:EXIT_WITH_ERROR
pause
exit /b -1
