@echo off

setlocal

call "%%~dp0__init__.bat" || goto :EOF

set /A NEST_LVL+=1

set "CMAKE_BUILD_TYPE=%~1"
rem cmake pack does not support particular target enpackage
rem set "CMAKE_BUILD_TARGET=%~2"

if not defined CMAKE_BUILD_TYPE set "CMAKE_BUILD_TYPE=*"
rem if not defined CMAKE_BUILD_TARGET set "CMAKE_BUILD_TARGET=BUNDLE"
set "CMAKE_BUILD_TARGET=BUNDLE"

set "PATH=%PATH%;%NSIS_INSTALL_ROOT%"

if "%CMAKE_BUILD_TYPE%" == "*" (
  for %%i in (%CMAKE_CONFIG_TYPES%) do (
    set "CMAKE_BUILD_TYPE=%%i"
    call :PACK || goto EXIT
  )
) else (
  call :PACK
)

goto EXIT

:PACK
pushd "%CMAKE_BUILD_ROOT%" && (
  call :CMD cmake --build . --config "%CMAKE_BUILD_TYPE%" --target "%CMAKE_BUILD_TARGET%" || ( popd & goto PACK_END )
  popd
)

:PACK_END
exit /b

:EXIT
set /A NEST_LVL-=1

if %NEST_LVL% EQU 0 pause

exit /b

:CMD
echo.^>%*
(%*)
exit /b
