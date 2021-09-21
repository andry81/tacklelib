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

if not exist "%TACKLELIB_PROJECT_OUTPUT_CONFIG_ROOT%\" ( mkdir "%TACKLELIB_PROJECT_OUTPUT_CONFIG_ROOT%" || exit /b 10 )

call "%%CONTOOLS_ROOT%%/build/load_config_dir.bat" -gen_user_config "%%TACKLELIB_PROJECT_INPUT_CONFIG_ROOT%%" "%%TACKLELIB_PROJECT_OUTPUT_CONFIG_ROOT%%" || exit /b

rem init external projects, common dependencies must be always initialized at first

if exist "%TACKLELIB_PROJECT_EXTERNALS_ROOT%/contools/__init__/__init__.bat" (
  call "%%TACKLELIB_PROJECT_EXTERNALS_ROOT%%/contools/__init__/__init__.bat" || exit /b
)

if not exist "%PROJECT_OUTPUT_ROOT%\" ( mkdir "%PROJECT_OUTPUT_ROOT%" || exit /b 11 )
if not exist "%PROJECT_LOG_ROOT%\" ( mkdir "%PROJECT_LOG_ROOT%" || exit /b 12 )

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
