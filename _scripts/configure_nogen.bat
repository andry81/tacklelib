@echo off

rem The script for cases where the IDE or down stream system doesn't have appropriate generator in the cmake.
rem For example, it can be the QtCreator.
rem To bypass the problem of inconvinient usage of environment variables in such circumstances and unability
rem to save them in version control system we have to directly generate cmake include file from a template file
rem and do manually change the values in a template. When the IDE starts execution the cmake list then it would
rem generate user local cmake from the template and include it loading required set of external variables.
rem To prepare this include we use this script.
rem 

setlocal

call "%%~dp0__init__.bat" || goto :EOF

set /A NEST_LVL+=1

set "CONFIGURE_FILE_IN=%~dp0..\%~nx0.in"

rem for safe parse
setlocal ENABLEDELAYEDEXPANSION

rem load command line from file
set "CMAKE_CMD_LINE="
for /F "usebackq eol=# tokens=* delims=" %%i in ("%CONFIGURE_FILE_IN%") do (
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
  ) || ( popd & goto EXIT )
  popd
)

:EXIT
set /A NEST_LVL-=1

if %NEST_LVL% EQU 0 pause

exit /b

:CMD
echo.^>%*
(
  %*
)
exit /b
