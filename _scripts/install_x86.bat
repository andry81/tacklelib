@echo off

setlocal

call "%%~dp0__init__.bat" || goto :EOF

set /A NEST_LVL+=1

set "CMAKE_BUILD_TYPE=%~1"
rem cmake install does not support particular target installation
rem set "CMAKE_BUILD_TARGET=%~2"

if not defined CMAKE_BUILD_TYPE set "CMAKE_BUILD_TYPE=*"
rem if not defined CMAKE_BUILD_TARGET set "CMAKE_BUILD_TARGET=INSTALL"
set "CMAKE_BUILD_TARGET=INSTALL"

if "%CMAKE_BUILD_TYPE%" == "*" (
  for %%i in (%CMAKE_CONFIG_TYPES%) do (
    set "CMAKE_BUILD_TYPE=%%i"
    call :INSTALL || goto EXIT
  )
) else (
  call :INSTALL
)

goto EXIT

:INSTALL
pushd "%CMAKE_BUILD_ROOT%" && (
  call :CMD cmake --build . --config "%CMAKE_BUILD_TYPE%" --target "%CMAKE_BUILD_TARGET%" || ( popd & goto INSTALL_END )
  popd
)

:INSTALL_END
exit /b

:EXIT
set /A NEST_LVL-=1

if %NEST_LVL% EQU 0 pause

exit /b

:CMD
echo.^>%*
(%*)
exit /b
