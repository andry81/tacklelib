@echo off

rem Not version constrol source files generator.

setlocal

call "%%~dp0__init__.bat" || goto :EOF

set /A NEST_LVL+=1

call :CANONICAL_PATH "%%~dp0.."
set "CONFIGURE_ROOT=%CANONICAL_PATH%"

echo."%CONFIGURE_ROOT%/includes/version.hpp"
(
  echo.#pragma once
  echo.
) > "%CONFIGURE_ROOT%/includes/version.hpp"

:EXIT
set /A NEST_LVL-=1

if %NEST_LVL% EQU 0 pause

exit /b

:CANONICAL_PATH
set "CANONICAL_PATH=%~dpf1"
set "CANONICAL_PATH=%CANONICAL_PATH:\=/%"
