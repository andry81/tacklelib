@echo off

if %__BASE_INIT__%0 NEQ 0 exit /b

if not defined NEST_LVL set NEST_LVL=0

set "CONFIGURE_ROOT=%~dp0"
set "CONFIGURE_ROOT=%CONFIGURE_ROOT:~0,-1%"

set "LOCAL_CONFIG_DIR_NAME=_config"

set "CONTOOLS_ROOT=%CONFIGURE_ROOT%\_scripts\tools"
set "UTILITY_ROOT=%CONTOOLS_ROOT%"

set __BASE_INIT__=1

exit /b
