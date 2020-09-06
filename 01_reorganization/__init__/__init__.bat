@echo off

if /i "%TACKLELIB_SCRIPTS_INIT0_DIR%" == "%~dp0" exit /b 0

set "TACKLELIB_SCRIPTS_INIT0_DIR=%~dp0"

rem CAUTION:
rem   Here is declared ONLY a basic set of system variables required immediately in this file.
rem   All the rest system variables will be loaded from the `config.*.vars` files.
rem

call :MAIN %%*
set "LASTERROR=%ERRORLEVEL%"

(
  set "MUST_LOAD_CONFIG="
  set "LASTERROR="
  exit /b %LASTERROR%
)

:MAIN
set "MUST_LOAD_CONFIG=%~1"
if not defined MUST_LOAD_CONFIG set "MUST_LOAD_CONFIG=1"

if not defined NEST_LVL set NEST_LVL=0

rem basic set of system variables
call :CANONICAL_PATH PROJECT_ROOT                 "%%~dp0.."

call :CANONICAL_PATH PROJECT_CONFIG_ROOT          "%%PROJECT_ROOT%%/_config"

call :CANONICAL_PATH PROJECT_OUTPUT_ROOT          "%%PROJECT_ROOT%%/_out"
call :CANONICAL_PATH PROJECT_OUTPUT_CONFIG_ROOT   "%%PROJECT_OUTPUT_ROOT%%/config"

call :CANONICAL_PATH PROJECT_LIBS_ROOT            "%%PROJECT_ROOT%%/_libs"

call :CANONICAL_PATH CONTOOLS_ROOT                "%%PROJECT_LIBS_ROOT%%/contools"

call :CANONICAL_PATH TACKLELIB_BASH_SCRIPTS_ROOT  "%%PROJECT_ROOT%%/bash/tacklelib"

set CONFIG_INDEX=system
call :LOAD_CONFIG || exit /b

if defined CHCP chcp %CHCP%

for %%i in (PROJECT_ROOT ^
  PROJECT_CACHE_ROOT PROJECT_LOG_ROOT PROJECT_CONFIG_ROOT PROJECT_CONFIG_SCRIPTS_ROOT PROJECT_SCRIPTS_ROOT PROJECT_SCRIPTS_TOOLS_ROOT PROJECT_LIBS_ROOT PROJECT_CMAKE_ROOT ^
  PROJECT_OUTPUT_ROOT PROJECT_OUTPUT_CONFIG_ROOT PROJECT_OUTPUT_CMAKE_ROOT ^
  CONTOOLS_ROOT ^
  TACKLELIB_CMAKE_CONFIG_ROOT TACKLELIB_CMAKE_OUTPUT_CONFIG_ROOT ^
  TACKLELIB_BASH_SCRIPTS_ROOT TACKLELIB_CMAKE_SCRIPTS_ROOT TACKLELIB_PYTHON_SCRIPTS_ROOT ^
  CMDOPLIB_PYTHON_SCRIPTS_ROOT ^
  PYXVCS_BASH_SCRIPTS_ROOT PYXVCS_PYTHON_SCRIPTS_ROOT PYXVCS_BATCH_SCRIPTS_ROOT) do (
  if not defined %%i (
    echo.%~nx0: error: `%%i` variable is not defined.
    exit /b 255
  ) >&2
)

set CONFIG_INDEX=0

:LOAD_CONFIG_LOOP
call :LOAD_CONFIG || exit /b
set /A CONFIG_INDEX+=1
goto LOAD_CONFIG_LOOP

:LOAD_CONFIG
if exist "%PROJECT_CONFIG_ROOT%/config.%CONFIG_INDEX%.vars.in" if exist "%PROJECT_OUTPUT_CONFIG_ROOT%/config.%CONFIG_INDEX%.vars" (
  call "%%CONTOOLS_ROOT%%/std/load_config.bat" "%%PROJECT_CONFIG_ROOT%%" "%%PROJECT_OUTPUT_CONFIG_ROOT%%" "config.%%CONFIG_INDEX%%.vars" && exit /b
)

if %MUST_LOAD_CONFIG% NEQ 0 (
  echo.%~nx0: error: `%PROJECT_OUTPUT_CONFIG_ROOT%/config.%CONFIG_INDEX%.vars` is not loaded.
  exit /b 255
)

if not exist "%PROJECT_OUTPUT_CMAKE_TESTS_CONFIG_ROOT%/config.%CONFIG_INDEX%.vars" exit /b 1

exit /b 0

:CANONICAL_PATH
setlocal DISABLEDELAYEDEXPANSION
set "RETURN_VALUE=%~dpf2"
set "RETURN_VALUE=%RETURN_VALUE:\=/%"
if "%RETURN_VALUE:~-1%" == "/" set "RETURN_VALUE=%RETURN_VALUE:~0,-1%"
(
  endlocal
  set "%~1=%RETURN_VALUE%"
)
exit /b 0
