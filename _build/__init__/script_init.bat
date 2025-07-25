@echo off

setlocal

if %IMPL_MODE%0 NEQ 0 goto IMPL

call "%%~dp0__init__.bat" || exit /b

call "%%~dp0check_vars.bat" TACKLELIB_PROJECT_ROOT PROJECT_OUTPUT_ROOT PROJECT_LOG_ROOT CONTOOLS_ROOT CONTOOLS_UTILS_BIN_ROOT || exit /b

call "%%TACKLELIB_PROJECT_ROOT%%/__init__/declare_builtins.bat" %%* || exit /b

call "%%CONTOOLS_ROOT%%/build/init_project_log.bat" "%%?~n0%%" || exit /b

call "%%CONTOOLS_ROOT%%/build/init_vars_file.bat" || exit /b

call "%%CONTOOLS_ROOT%%/std/callshift.bat" -skip 2 1 call "%%%%CONTOOLS_ROOT%%%%/exec/exec_callf_prefix.bat" -- %%* || exit /b

rem The caller must exit after this exit.
exit /b 0

:IMPL
rem CAUTION: We must to reinit the builtin variables in case if `IMPL_MODE` was already setup outside.
call "%%CONTOOLS_ROOT%%/std/declare_builtins.bat" %%* || exit /b

rem load initialization environment variables
if defined INIT_VARS_FILE call "%%CONTOOLS_ROOT%%/std/set_vars_from_file.bat" "%%INIT_VARS_FILE%%"

call "%%CONTOOLS_ROOT%%/std/get_cmdline.bat" %%*
call "%%CONTOOLS_ROOT%%/std/echo_var.bat" RETURN_VALUE ">"
echo;

rem The caller can continue after this exit.
exit /b 0
