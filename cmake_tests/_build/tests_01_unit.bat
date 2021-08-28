@echo off

setlocal

call "%%~dp0__init__/__init0__.bat" || goto INIT_EXIT

if %IMPL_MODE%0 NEQ 0 goto IMPL

rem no local logging if nested call
set WITH_LOGGING=0
if %NEST_LVL%0 EQU 0 set WITH_LOGGING=1

if %WITH_LOGGING% EQU 0 goto IMPL

if not exist "%SCRIPTS_LOGS_ROOT%\.log" mkdir "%SCRIPTS_LOGS_ROOT%\.log"

rem use stdout/stderr redirection with logging
call "%%CONTOOLS_ROOT%%\get_datetime.bat"
set "LOG_FILE_NAME_SUFFIX=%RETURN_VALUE:~0,4%'%RETURN_VALUE:~4,2%'%RETURN_VALUE:~6,2%_%RETURN_VALUE:~8,2%'%RETURN_VALUE:~10,2%'%RETURN_VALUE:~12,2%''%RETURN_VALUE:~15,3%"

set IMPL_MODE=1
rem CAUTION:
rem   We should avoid use handles 3 and 4 while the redirection has take a place because handles does reuse
rem   internally from left to right when being redirected externally.
rem   Example: if `1` is redirected, then `3` is internally reused, then if `2` redirected, then `4` is internally reused and so on.
rem   The discussion of the logic:
rem   https://stackoverflow.com/questions/9878007/why-doesnt-my-stderr-redirection-end-after-command-finishes-and-how-do-i-fix-i/9880156#9880156
rem   A partial analisis:
rem   https://www.dostips.com/forum/viewtopic.php?p=14612#p14612
rem
"%COMSPEC%" /C call %0 %* 2>&1 | "%CONTOOLS_UTILITIES_BIN_ROOT%\ritchielawrence\mtee.exe" /E "%SCRIPTS_LOGS_ROOT%\.log\%LOG_FILE_NAME_SUFFIX%.%~n0.log"
exit /b

:IMPL
call "%%~dp0__init__/__init1__.bat" || goto INIT_EXIT

set /A NEST_LVL+=1

call :MAIN %%*
set LASTERROR=%ERRORLEVEL%

set /A NEST_LVL-=1

if %NEST_LVL%0 EQU 0 call "%%CONTOOLS_ROOT%%/std/pause.bat"

exit /b %LASTERROR%

:MAIN
call :CMD cmake ^
  "-DCMAKE_MODULE_PATH=%%TESTS_ROOT%%;%%PROJECT_ROOT%%/cmake" ^
  "-DPROJECT_ROOT=%%PROJECT_ROOT%%" ^
  "-DTESTS_ROOT=%%TESTS_ROOT%%" ^
  "-DTACKLELIB_TESTLIB_TESTSCRIPT_FILE=%%TESTS_ROOT%%/%%~n0.cmake" ^
  "-DTACKLELIB_TESTLIB_ROOT=%%PROJECT_ROOT%%/cmake/tacklelib/testlib" ^
  -P ^
  "%%PROJECT_ROOT%%/cmake/tacklelib/testlib/tools/RunTestLib.cmake" ^
  %%* || exit /b

:TEST_END
exit /b

:CMD
echo.^>%*
echo.
(
  %*
)
exit /b

:INIT_EXIT
set LASTERROR=%ERRORLEVEL%

if %NEST_LVL%0 EQU 0 call "%%CONTOOLS_ROOT%%/std/pause.bat"

exit /b %LASTERROR%
