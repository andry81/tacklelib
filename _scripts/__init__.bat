@echo off

rem CAUTION:
rem  In case of usage the QtCreator there is set of special broken cases you have to avoid:
rem  1. Invalid characters in paths: `(`, `)` and `.`.
rem  2. Non english locale in paths.

call :CANONICAL_PATH "%%~dp0.."
set "PROJECT_ROOT=%PATH_VALUE%"

set "CMAKE_OUTPUT_ROOT=%PROJECT_ROOT%/_out"

set "CMAKE_BUILD_ROOT=%CMAKE_OUTPUT_ROOT%/build"
set "CMAKE_BIN_ROOT=%CMAKE_OUTPUT_ROOT%/bin"
set "CMAKE_LIB_ROOT=%CMAKE_OUTPUT_ROOT%/lib"
set "CMAKE_INSTALL_ROOT=%CMAKE_OUTPUT_ROOT%/install"
set "CMAKE_CPACK_ROOT=%CMAKE_OUTPUT_ROOT%/pack"

set "CMAKE_GENERATOR_TOOLSET=Visual Studio 14 2015"

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
