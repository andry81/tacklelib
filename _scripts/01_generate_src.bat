@echo off

rem Source files generator script.

setlocal

call "%%~dp0__init0__.bat" || goto INIT_EXIT

set /A NEST_LVL+=1


set "CONFIG_FILE_IN=%PROJECT_ROOT%\config\_scripts\01\%~n0.in"

rem load command line from file
for /F "usebackq eol=# tokens=1,* delims=|" %%i in ("%CONFIG_FILE_IN%") do (
  set "FROM_FILE=%%i"
  set "TO_FILE=%%j"
  call :PROCESS_FILE_TMPLS
)

set "CONFIG_FILE_IN=%PROJECT_ROOT%\config\_scripts\01\%~n0.deps%~x0.in"

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
set /A NEST_LVL-=1

:INIT_EXIT
if %NEST_LVL%0 EQU 0 pause

exit /b
