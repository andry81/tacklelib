@echo off

setlocal

call "%%~dp0__init__.bat" || goto :EOF

set /A NEST_LVL+=1

rem call "%%~dp0configure_gen.bat" || goto EXIT
rem echo.

set "CMAKE_BUILD_TYPE=%~1"
set "CMAKE_BUILD_TARGET=%~2"

if not defined CMAKE_BUILD_TYPE set "CMAKE_BUILD_TYPE=*"
if not defined CMAKE_BUILD_TARGET set "CMAKE_BUILD_TARGET=ALL_BUILD"

if "%CMAKE_BUILD_TYPE%" == "*" (
  for %%i in (%CMAKE_CONFIG_TYPES%) do (
    set "CMAKE_BUILD_TYPE=%%i"
    call :BUILD || goto EXIT
  )
) else (
  call :BUILD
)

goto EXIT

:BUILD
pushd "%CMAKE_BUILD_ROOT%" && (
  call :CMD cmake --build . --config "%CMAKE_BUILD_TYPE%" --target "%CMAKE_BUILD_TARGET%" || ( popd & goto BUILD_END )
  popd
)

:BUILD_END
exit /b

:EXIT
set /A NEST_LVL-=1

if %NEST_LVL% EQU 0 pause

exit /b

:CMD
echo.^>%*
(%*)
exit /b
