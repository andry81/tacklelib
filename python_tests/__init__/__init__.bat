@echo off

if defined TACKLELIB_PYTHON_TESTS_ROOT_INIT0_DIR if exist "%TACKLELIB_PYTHON_TESTS_ROOT_INIT0_DIR%\*" exit /b 0

call "%%~dp0..\..\__init__\__init__.bat" || exit /b

set "TACKLELIB_PYTHON_TESTS_ROOT_INIT0_DIR=%~d0"

if not defined TESTS_PROJECT_ROOT                         call "%%TACKLELIB_PROJECT_ROOT%%/__init__/canonical_path.bat" TESTS_PROJECT_ROOT                       "%%~dp0.."
if not defined TESTS_PROJECT_INPUT_CONFIG_ROOT            call "%%TACKLELIB_PROJECT_ROOT%%/__init__/canonical_path.bat" TESTS_PROJECT_INPUT_CONFIG_ROOT          "%%TESTS_PROJECT_ROOT%%/_config"
if not defined TESTS_PROJECT_OUTPUT_CONFIG_ROOT           call "%%TACKLELIB_PROJECT_ROOT%%/__init__/canonical_path.bat" TESTS_PROJECT_OUTPUT_CONFIG_ROOT         "%%TACKLELIB_PROJECT_OUTPUT_CONFIG_ROOT%%/python_tests"

if not exist "%TESTS_PROJECT_OUTPUT_CONFIG_ROOT%\" ( mkdir "%TESTS_PROJECT_OUTPUT_CONFIG_ROOT%" || exit /b 10 )

call "%%CONTOOLS_ROOT%%/build/load_config_dir.bat" -full_parse -gen_user_config "%%TESTS_PROJECT_INPUT_CONFIG_ROOT%%" "%%TESTS_PROJECT_OUTPUT_CONFIG_ROOT%%" || exit /b

if defined CHCP chcp %CHCP%

exit /b 0
