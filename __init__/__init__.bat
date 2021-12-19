@echo off

if /i "%TACKLELIB_PROJECT_ROOT_INIT0_DIR%" == "%~dp0" exit /b 0

set "TACKLELIB_PROJECT_ROOT_INIT0_DIR=%~dp0"

if not defined NEST_LVL set NEST_LVL=0

if not defined TACKLELIB_PROJECT_ROOT                       call "%%~dp0canonical_path.bat" TACKLELIB_PROJECT_ROOT                 "%%~dp0.."
if not defined TACKLELIB_PROJECT_EXTERNALS_ROOT             call "%%~dp0canonical_path.bat" TACKLELIB_PROJECT_EXTERNALS_ROOT       "%%TACKLELIB_PROJECT_ROOT%%/_externals"

if not defined PROJECT_OUTPUT_ROOT                          call "%%~dp0canonical_path.bat" PROJECT_OUTPUT_ROOT                    "%%TACKLELIB_PROJECT_ROOT%%/_out"
if not defined PROJECT_LOG_ROOT                             call "%%~dp0canonical_path.bat" PROJECT_LOG_ROOT                       "%%TACKLELIB_PROJECT_ROOT%%/.log"

if not defined TACKLELIB_PROJECT_INPUT_CONFIG_ROOT          call "%%~dp0canonical_path.bat" TACKLELIB_PROJECT_INPUT_CONFIG_ROOT    "%%TACKLELIB_PROJECT_ROOT%%/_config"
if not defined TACKLELIB_PROJECT_OUTPUT_CONFIG_ROOT         call "%%~dp0canonical_path.bat" TACKLELIB_PROJECT_OUTPUT_CONFIG_ROOT   "%%PROJECT_OUTPUT_ROOT%%/config/tacklelib"

rem init external projects

if exist "%TACKLELIB_PROJECT_EXTERNALS_ROOT%/contools/__init__/__init__.bat" (
  call "%%TACKLELIB_PROJECT_EXTERNALS_ROOT%%/contools/__init__/__init__.bat" || exit /b
)

if not exist "%TACKLELIB_PROJECT_OUTPUT_CONFIG_ROOT%\" ( mkdir "%TACKLELIB_PROJECT_OUTPUT_CONFIG_ROOT%" || exit /b 10 )

if not defined LOAD_CONFIG_VERBOSE if %INIT_VERBOSE%0 NEQ 0 set LOAD_CONFIG_VERBOSE=1

call "%%CONTOOLS_ROOT%%/build/load_config_dir.bat" -lite_parse -gen_user_config "%%TACKLELIB_PROJECT_INPUT_CONFIG_ROOT%%" "%%TACKLELIB_PROJECT_OUTPUT_CONFIG_ROOT%%" || exit /b

if not exist "%PROJECT_OUTPUT_ROOT%\" ( mkdir "%PROJECT_OUTPUT_ROOT%" || exit /b 11 )
if not exist "%PROJECT_LOG_ROOT%\" ( mkdir "%PROJECT_LOG_ROOT%" || exit /b 12 )

if defined CHCP call "%%CONTOOLS_ROOT%%/std/chcp.bat" %%CHCP%%

exit /b 0
