@echo off

rem Source files generator script.

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
"%COMSPEC%" /C call %0 %* 2>&1 | "%CONTOOLS_ROOT%\tee.exe" "%SCRIPTS_LOGS_ROOT%\.log\%LOG_FILE_NAME_SUFFIX%.%~n0.log"
exit /b

:IMPL
set /A NEST_LVL+=1

call :MAIN %%*
set LASTERROR=%ERRORLEVEL%

set /A NEST_LVL-=1

if %NEST_LVL%0 EQU 0 call "%%CONTOOLS_ROOT%%/std/pause.bat"

exit /b %LASTERROR%

:MAIN
set "CONFIG_FILE_IN=%PROJECT_ROOT%\_config\_scripts\01\%~n0.in"

rem load command line from file
for /F "usebackq eol=# tokens=1,* delims=|" %%i in ("%CONFIG_FILE_IN%") do (
  set "FROM_FILE=%%i"
  set "TO_FILE=%%j"
  call :PROCESS_FILE_TMPLS
)

set "CONFIG_FILE_IN=%PROJECT_ROOT%\_config\_scripts\01\%~n0.deps%~x0.in"

rem load command line from file
for /F "usebackq eol=# tokens=1,* delims=|" %%i in ("%CONFIG_FILE_IN%") do (
  set "SCRIPT_FILE_PATH=%%i"
  set "SCRIPT_CMD_LINE=%%j"
  call :PROCESS_SCRIPTS
)

exit /b

:PROCESS_FILE_TMPLS
echo."%PROJECT_ROOT%/%FROM_FILE%" -^> "%PROJECT_ROOT%/%TO_FILE%"
(
  type "%PROJECT_ROOT:/=\%\%FROM_FILE:/=\%"
) > "%PROJECT_ROOT%/%TO_FILE%"

exit /b

:PROCESS_SCRIPTS
echo.^>"%PROJECT_ROOT%/%SCRIPT_FILE_PATH%" %SCRIPT_CMD_LINE%

call "%%PROJECT_ROOT%%/%%SCRIPT_FILE_PATH%%" %SCRIPT_CMD_LINE% || exit /b
echo.

exit /b 0

:INIT_EXIT
set LASTERROR=%ERRORLEVEL%

if %NEST_LVL%0 EQU 0 call "%%CONTOOLS_ROOT%%/std/pause.bat"

exit /b %LASTERROR%
