@echo off

rem Configuration variable files generator script.

setlocal

set IN_GENERATOR_SCRIPT=1

call "%%~dp0__init__/__init1__.bat" || goto INIT_EXIT

set /A NEST_LVL+=1


set "CMDLINE_SYSTEM_FILE_IN=%PROJECT_ROOT%\cmake_tests\_config\_scripts\01\%~n0.system%~x0.in"

for %%i in ("%CMDLINE_SYSTEM_FILE_IN%") do (
  set "CMDLINE_FILE_IN=%%i"
  call :GENERATE || goto EXIT
)

set "CONFIG_FILE_IN=%PROJECT_ROOT%\cmake_tests\_config\_scripts\01\%~n0.deps%~x0.in"

rem load command line from file
for /F "usebackq eol=# tokens=1,* delims=|" %%i in ("%CONFIG_FILE_IN%") do (
  set "SCRIPT_FILE_PATH=%%i"
  set "SCRIPT_CMD_LINE=%%j"
  call :PROCESS_SCRIPTS
)

goto EXIT

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

pushd "%CMAKE_BUILD_ROOT%" && (
  (
    call :CMD cmake %CMAKE_CMD_LINE%
  ) || ( popd & goto GENERATE_END )
  popd
)

:GENERATE_END
exit /b

:PROCESS_SCRIPTS
echo.^>"%PROJECT_ROOT%/%SCRIPT_FILE_PATH%" %SCRIPT_CMD_LINE%

call "%%PROJECT_ROOT%%/%%SCRIPT_FILE_PATH%%" %SCRIPT_CMD_LINE% || exit /b
echo.

exit /b 0

:CMD
echo.^>%*
echo.
(
  %*
)
exit /b

:EXIT
set /A NEST_LVL-=1

:INIT_EXIT
if %NEST_LVL%0 EQU 0 pause

exit /b
