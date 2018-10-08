@echo off

rem Not version control source files generator.

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

echo."%CONFIGURE_ROOT%/includes/setup.hpp.in" -^> "%CONFIGURE_ROOT%/includes/setup.hpp"
(
  type "%CONFIGURE_ROOT:/=\%\includes\setup.hpp.in"
) > "%CONFIGURE_ROOT%/includes/setup.hpp"

echo."%CONFIGURE_ROOT%/includes/debug.hpp.in" -^> "%CONFIGURE_ROOT%/includes/debug.hpp"
(
  type "%CONFIGURE_ROOT:/=\%\includes\debug.hpp.in"
) > "%CONFIGURE_ROOT%/includes/debug.hpp"

echo."%CONFIGURE_ROOT%/includes/optimization.hpp.in" -^> "%CONFIGURE_ROOT%/includes/optimization.hpp"
(
  type "%CONFIGURE_ROOT:/=\%\includes\optimization.hpp.in"
) > "%CONFIGURE_ROOT%/includes/optimization.hpp"

echo."%CONFIGURE_ROOT%/src/setup.hpp.in" -^> "%CONFIGURE_ROOT%/src/setup.hpp"
(
  type "%CONFIGURE_ROOT:/=\%\src\setup.hpp.in"
) > "%CONFIGURE_ROOT%/src/setup.hpp"

echo."%CONFIGURE_ROOT%/src/debug.hpp.in" -^> "%CONFIGURE_ROOT%/src/debug.hpp"
(
  type "%CONFIGURE_ROOT:/=\%\src\debug.hpp.in"
) > "%CONFIGURE_ROOT%/src/debug.hpp"

echo."%CONFIGURE_ROOT%/src/optimization.hpp.in" -^> "%CONFIGURE_ROOT%/src/optimization.hpp"
(
  type "%CONFIGURE_ROOT:/=\%\src\optimization.hpp.in"
) > "%CONFIGURE_ROOT%/src/optimization.hpp"

:EXIT
set /A NEST_LVL-=1

if %NEST_LVL% EQU 0 pause

exit /b

:CANONICAL_PATH
set "CANONICAL_PATH=%~dpf1"
set "CANONICAL_PATH=%CANONICAL_PATH:\=/%"
