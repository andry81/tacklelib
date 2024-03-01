@echo off

if /i "%TACKLELIB_PROJECT_ROOT_INIT0_DIR%" == "%~dp0" exit /b 0

set "TACKLELIB_PROJECT_ROOT_INIT0_DIR=%~dp0"

if not defined NEST_LVL set NEST_LVL=0

rem Do not make a file or a directory
if defined NO_GEN set /A NO_GEN+=0

rem Do not make a log directory or a log file
if defined NO_LOG set /A NO_LOG+=0

rem Do not make a log output or stdio duplication into files
if defined NO_LOG_OUTPUT set /A NO_LOG_OUTPUT+=0

rem Do not change code page
if defined NO_CHCP set /A NO_CHCP+=0

if not defined TACKLELIB_PROJECT_ROOT                       call "%%~dp0canonical_path.bat" TACKLELIB_PROJECT_ROOT                 "%%~dp0.."
if not defined TACKLELIB_PROJECT_EXTERNALS_ROOT             call "%%~dp0canonical_path.bat" TACKLELIB_PROJECT_EXTERNALS_ROOT       "%%TACKLELIB_PROJECT_ROOT%%/_externals"

if not exist "%TACKLELIB_PROJECT_EXTERNALS_ROOT%\*" (
  echo.%~nx0: error: TACKLELIB_PROJECT_EXTERNALS_ROOT directory does not exist: "%TACKLELIB_PROJECT_EXTERNALS_ROOT%".
  exit /b 255
) >&2

if not defined PROJECT_OUTPUT_ROOT                          call "%%~dp0canonical_path.bat" PROJECT_OUTPUT_ROOT                    "%%TACKLELIB_PROJECT_ROOT%%/_out"
if not defined PROJECT_LOG_ROOT                             call "%%~dp0canonical_path.bat" PROJECT_LOG_ROOT                       "%%TACKLELIB_PROJECT_ROOT%%/.log"

if not defined TACKLELIB_PROJECT_INPUT_CONFIG_ROOT          call "%%~dp0canonical_path.bat" TACKLELIB_PROJECT_INPUT_CONFIG_ROOT    "%%TACKLELIB_PROJECT_ROOT%%/_config"
if not defined TACKLELIB_PROJECT_OUTPUT_CONFIG_ROOT         call "%%~dp0canonical_path.bat" TACKLELIB_PROJECT_OUTPUT_CONFIG_ROOT   "%%PROJECT_OUTPUT_ROOT%%/config/tacklelib"

rem retarget externals of an external project

if not defined CONTOOLS_PROJECT_EXTERNALS_ROOT              call "%%~dp0canonical_path.bat" CONTOOLS_PROJECT_EXTERNALS_ROOT        "%%TACKLELIB_PROJECT_EXTERNALS_ROOT%%"

rem init external projects

if exist "%TACKLELIB_PROJECT_EXTERNALS_ROOT%/contools/__init__/__init__.bat" (
  call "%%TACKLELIB_PROJECT_EXTERNALS_ROOT%%/contools/__init__/__init__.bat" %%* || exit /b
)

if %NO_GEN%0 EQU 0 (
  call "%%CONTOOLS_ROOT%%/std/mkdir_if_notexist.bat" "%%TACKLELIB_PROJECT_OUTPUT_CONFIG_ROOT%%" || exit /b 10
)

if not defined LOAD_CONFIG_VERBOSE if %INIT_VERBOSE%0 NEQ 0 set LOAD_CONFIG_VERBOSE=1

if %NO_GEN%0 EQU 0 (
  call "%%CONTOOLS_ROOT%%/build/load_config_dir.bat" %%* -gen_user_config "%%TACKLELIB_PROJECT_INPUT_CONFIG_ROOT%%" "%%TACKLELIB_PROJECT_OUTPUT_CONFIG_ROOT%%" || exit /b
) else call "%%CONTOOLS_ROOT%%/build/load_config_dir.bat" %%* "%%TACKLELIB_PROJECT_INPUT_CONFIG_ROOT%%" "%%TACKLELIB_PROJECT_OUTPUT_CONFIG_ROOT%%" || exit /b

if %NO_GEN%0 EQU 0 (
  call "%%CONTOOLS_ROOT%%/std/mkdir_if_notexist.bat" "%%PROJECT_OUTPUT_ROOT%%" || exit /b 11
)

if %NO_CHCP%0 EQU 0 (
  if defined CHCP call "%%CONTOOLS_ROOT%%/std/chcp.bat" %%CHCP%%
)

exit /b 0
