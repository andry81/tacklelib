@echo off

rem Configuration variable files generator script.

setlocal

call "%%~dp0__init__/__init0__.bat" || exit

for %%i in (PROJECT_ROOT PROJECT_LOG_ROOT CONTOOLS_ROOT) do (
  if not defined %%i (
    echo.%~nx0: error: `%%i` variable is not defined.
    exit /b 255
  ) >&2
)

if %IMPL_MODE%0 NEQ 0 goto IMPL

rem no local logging if nested call
set WITH_LOGGING=0
if %NEST_LVL%0 EQU 0 set WITH_LOGGING=1

if %WITH_LOGGING% EQU 0 goto IMPL

if not exist "%PROJECT_LOG_ROOT%" ( mkdir "%PROJECT_LOG_ROOT%" || exit )

rem use stdout/stderr redirection with logging
call "%%CONTOOLS_ROOT%%/std/get_wmic_local_datetime.bat"
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
"%COMSPEC%" /C call %0 %* 2>&1 | "%CONTOOLS_ROOT%/unxutils/tee.exe" "%PROJECT_LOG_ROOT%/%LOG_FILE_NAME_SUFFIX%.%~n0.log"
exit /b

:IMPL
set IN_GENERATOR_SCRIPT=1

call "%%~dp0__init__/__init1__.bat" || exit

set /A NEST_LVL+=1

call :MAIN %%*
set LASTERROR=%ERRORLEVEL%

set /A NEST_LVL-=1

if %NEST_LVL%0 EQU 0 pause

exit /b %LASTERROR%

:MAIN
set "CMDLINE_SYSTEM_FILE_IN=%PROJECT_CONFIG_ROOT%/_scripts/01/%~n0.system%~x0.in"

for %%i in ("%CMDLINE_SYSTEM_FILE_IN%") do (
  set "CMDLINE_FILE_IN=%%i"
  call :GENERATE || exit /b
)

exit /b

:GENERATE
rem for safe parse
setlocal ENABLEDELAYEDEXPANSION

rem load command line from file
set "CMAKE_CMD_LINE="
for /F "usebackq eol=# tokens=* delims=" %%i in (%CMDLINE_FILE_IN%) do (
  if defined CMAKE_CMD_LINE (
    set "CMAKE_CMD_LINE=!CMAKE_CMD_LINE! %%i"
  ) else (
    set "CMAKE_CMD_LINE=%%i"
  )
)

rem safe variable return over endlocal with delayed expansion
for /F "eol=# tokens=* delims=" %%i in ("!CMAKE_CMD_LINE!") do (
  endlocal
  set "CMAKE_CMD_LINE=%%i"
)

call :CMD cmake %CMAKE_CMD_LINE%
exit /b

:CMD
echo.^>%*
echo.
(
  %*
)
exit /b
