@echo off

if defined TACKLELIB_PYTHON_TESTS_ROOT_INIT0_DIR if exist "%TACKLELIB_PYTHON_TESTS_ROOT_INIT0_DIR%\" exit /b 0

call "%%~dp0..\..\__init__\__init__.bat" || exit /b

set "TACKLELIB_PYTHON_TESTS_ROOT_INIT0_DIR=%~d0"

if not defined TESTS_PROJECT_ROOT                         call :CANONICAL_PATH TESTS_PROJECT_ROOT                       "%%~dp0.."
if not defined TESTS_PROJECT_INPUT_CONFIG_ROOT            call :CANONICAL_PATH TESTS_PROJECT_INPUT_CONFIG_ROOT          "%%TESTS_PROJECT_ROOT%%/_config"
if not defined TESTS_PROJECT_OUTPUT_CONFIG_ROOT           call :CANONICAL_PATH TESTS_PROJECT_OUTPUT_CONFIG_ROOT         "%%TACKLELIB_PROJECT_OUTPUT_CONFIG_ROOT%%/python_tests"

if not exist "%TESTS_PROJECT_OUTPUT_CONFIG_ROOT%\" ( mkdir "%TESTS_PROJECT_OUTPUT_CONFIG_ROOT%" || exit /b 10 )

call "%%CONTOOLS_ROOT%%/build/load_config_dir.bat" -full_parse -gen_user_config "%%TESTS_PROJECT_INPUT_CONFIG_ROOT%%" "%%TESTS_PROJECT_OUTPUT_CONFIG_ROOT%%" || exit /b

if defined CHCP chcp %CHCP%

exit /b 0

:CANONICAL_PATH
setlocal DISABLEDELAYEDEXPANSION
for /F "eol= tokens=* delims=" %%i in ("%~2\.") do set "RETURN_VALUE=%%~fi"
rem required in cmake
set "RETURN_VALUE=%RETURN_VALUE:\=/%"
(
  endlocal
  set "%~1=%RETURN_VALUE%"
)
exit /b 0
