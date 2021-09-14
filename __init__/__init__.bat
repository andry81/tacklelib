@echo off

if /i "%TACKLELIB_PROJECT_ROOT_INIT0_DIR%" == "%~dp0" exit /b 0

set "TACKLELIB_PROJECT_ROOT_INIT0_DIR=%~dp0"

if not defined NEST_LVL set NEST_LVL=0

rem basic set of system variables
if not defined TACKLELIB_PROJECT_ROOT                       call :CANONICAL_PATH TACKLELIB_PROJECT_ROOT                 "%%~dp0.."
if not defined TACKLELIB_PROJECT_EXTERNALS_ROOT             call :CANONICAL_PATH TACKLELIB_PROJECT_EXTERNALS_ROOT       "%%TACKLELIB_PROJECT_ROOT%%/_externals"

if not defined PROJECT_OUTPUT_ROOT                          call :CANONICAL_PATH PROJECT_OUTPUT_ROOT                    "%%TACKLELIB_PROJECT_ROOT%%/_out"
if not defined PROJECT_LOG_ROOT                             call :CANONICAL_PATH PROJECT_LOG_ROOT                       "%%TACKLELIB_PROJECT_ROOT%%/.log"

if not defined TACKLELIB_PROJECT_INPUT_CONFIG_ROOT          call :CANONICAL_PATH TACKLELIB_PROJECT_INPUT_CONFIG_ROOT    "%%TACKLELIB_PROJECT_ROOT%%/_config"
if not defined TACKLELIB_PROJECT_OUTPUT_CONFIG_ROOT         call :CANONICAL_PATH TACKLELIB_PROJECT_OUTPUT_CONFIG_ROOT   "%%PROJECT_OUTPUT_ROOT%%/config/tacklelib"

if not defined TACKLELIB_PROJECT_BUILD_ROOT                 call :CANONICAL_PATH TACKLELIB_PROJECT_BUILD_ROOT           "%%TACKLELIB_PROJECT_ROOT%%/_build"

if not defined TACKLELIB_BASH_ROOT                          call :CANONICAL_PATH TACKLELIB_BASH_ROOT                    "%%TACKLELIB_PROJECT_ROOT%%/bash"
if not defined TACKLELIB_CMAKE_ROOT                         call :CANONICAL_PATH TACKLELIB_CMAKE_ROOT                   "%%TACKLELIB_PROJECT_ROOT%%/cmake"
if not defined TACKLELIB_PYTHON_ROOT                        call :CANONICAL_PATH TACKLELIB_PYTHON_ROOT                  "%%TACKLELIB_PROJECT_ROOT%%/python"
if not defined TACKLELIB_VBS_ROOT                           call :CANONICAL_PATH TACKLELIB_VBS_ROOT                     "%%TACKLELIB_PROJECT_ROOT%%/vbs"

rem init external projects

if exist "%TACKLELIB_PROJECT_EXTERNALS_ROOT%/contools/__init__/__init__.bat" (
  call "%%TACKLELIB_PROJECT_EXTERNALS_ROOT%%/contools/__init__/__init__.bat" || exit /b
)

if not exist "%PROJECT_OUTPUT_ROOT%\" ( mkdir "%PROJECT_OUTPUT_ROOT%" || exit /b 10 )
if not exist "%PROJECT_LOG_ROOT%\" ( mkdir "%PROJECT_LOG_ROOT%" || exit /b 11 )
if not exist "%TACKLELIB_PROJECT_OUTPUT_CONFIG_ROOT%\" ( mkdir "%TACKLELIB_PROJECT_OUTPUT_CONFIG_ROOT%" || exit /b 12 )

call "%%CONTOOLS_ROOT%%/std/load_config_dir.bat" -gen_config "%%TACKLELIB_PROJECT_INPUT_CONFIG_ROOT%%" "%%TACKLELIB_PROJECT_OUTPUT_CONFIG_ROOT%%" || exit /b

if defined CHCP chcp %CHCP%

exit /b 0

:CANONICAL_PATH
setlocal DISABLEDELAYEDEXPANSION
for /F "eol= tokens=* delims=" %%i in ("%~2\.") do set "RETURN_VALUE=%%~fi"
rem set "RETURN_VALUE=%RETURN_VALUE:\=/%"
(
  endlocal
  set "%~1=%RETURN_VALUE%"
)
exit /b 0
