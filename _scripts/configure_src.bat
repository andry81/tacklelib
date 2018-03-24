@echo off

rem Not version constrol source files generator.

setlocal

call "%%~dp0__init__.bat" || goto :EOF

set /A NEST_LVL+=1

echo."%PROJECT_ROOT%/includes/version.hpp"
(
  echo.#pragma once
  echo.
) > "%PROJECT_ROOT%/includes/version.hpp"

:EXIT
set /A NEST_LVL-=1

if %NEST_LVL% EQU 0 pause

exit /b
