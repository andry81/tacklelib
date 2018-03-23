@echo off

setlocal

set "CONFIGURE_ROOT=%~dp0"
set "CONFIGURE_ROOT=%CONFIGURE_ROOT:~0,-1%"
set "CONFIGURE_ROOT=%CONFIGURE_ROOT:\=/%"

echo."%CONFIGURE_ROOT%/includes/version.hpp"
(
  echo.#pragma once
  echo.
) > "%CONFIGURE_ROOT%/includes/version.hpp"

pause

exit /b 0
