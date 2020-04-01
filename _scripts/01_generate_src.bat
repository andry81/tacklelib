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
"%COMSPEC%" /C call %0 %* 2>&1 | "%CONTOOLS_ROOT%\wtee.exe" "%SCRIPTS_LOGS_ROOT%\.log\%LOG_FILE_NAME_SUFFIX%.%~n0.log"
exit /b

:IMPL
set /A NEST_LVL+=1

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

goto EXIT

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

:EXIT
set LASTERROR=%ERRORLEVEL%

set /A NEST_LVL-=1

if %NEST_LVL%0 EQU 0 pause

exit /b %LASTERROR%

:INIT_EXIT
set LASTERROR=%ERRORLEVEL%

if %NEST_LVL%0 EQU 0 pause

exit /b %LASTERROR%
