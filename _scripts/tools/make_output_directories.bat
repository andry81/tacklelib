@echo off

setlocal

set "CMAKE_BUILD_TYPE=%~1"

if defined CMAKE_BUILD_TYPE (
  set "CMAKE_BUILD_DIR=%CMAKE_BUILD_ROOT%\%CMAKE_BUILD_TYPE%"
  set "CMAKE_BIN_DIR=%CMAKE_BIN_ROOT%\%CMAKE_BUILD_TYPE%"
  set "CMAKE_LIB_DIR=%CMAKE_LIB_ROOT%\%CMAKE_BUILD_TYPE%"
  set "CMAKE_CPACK_DIR=%CMAKE_CPACK_ROOT%\%CMAKE_BUILD_TYPE%"
) else (
  set "CMAKE_BUILD_DIR=%CMAKE_BUILD_ROOT%"
  set "CMAKE_BIN_DIR=%CMAKE_BIN_ROOT%"
  set "CMAKE_LIB_DIR=%CMAKE_LIB_ROOT%"
  set "CMAKE_CPACK_DIR=%CMAKE_CPACK_ROOT%"
)

call :PARENT_DIR "%%CMAKE_OUTPUT_ROOT%%"
if not defined PARENT_DIR (
  echo.%~nx0: error: parent directory of the CMAKE_OUTPUT_ROOT does not exist "%CMAKE_OUTPUT_ROOT%".
  exit /b 1
)

if not exist "%CMAKE_OUTPUT_ROOT%" ( mkdir "%CMAKE_OUTPUT_ROOT%" || exit /b )

if defined CMAKE_OUTPUT_GENERATOR_DIR (
  call :PARENT_DIR "%%CMAKE_OUTPUT_GENERATOR_DIR%%"
  if not defined PARENT_DIR (
    echo.%~nx0: error: parent directory of the CMAKE_OUTPUT_GENERATOR_DIR does not exist "%CMAKE_OUTPUT_GENERATOR_DIR%".
    exit /b 2
  )

  if not exist "%CMAKE_OUTPUT_DIR%" ( mkdir "%CMAKE_OUTPUT_DIR%" || exit /b )
)

call :PARENT_DIR "%%CMAKE_OUTPUT_DIR%%"
if not defined PARENT_DIR (
  echo.%~nx0: error: parent directory of the CMAKE_OUTPUT_DIR does not exist "%CMAKE_OUTPUT_DIR%".
  exit /b 3
)

if not exist "%CMAKE_OUTPUT_DIR%" ( mkdir "%CMAKE_OUTPUT_DIR%" || exit /b )

if not exist "%CMAKE_BUILD_ROOT%" ( mkdir "%CMAKE_BUILD_DIR%" || exit /b )
if not exist "%CMAKE_BIN_ROOT%" ( mkdir "%CMAKE_BIN_DIR%" || exit /b )
if not exist "%CMAKE_LIB_ROOT%" ( mkdir "%CMAKE_LIB_DIR%" || exit /b )
if not exist "%CMAKE_INSTALL_ROOT%" ( mkdir "%CMAKE_INSTALL_ROOT%" || exit /b )
if not exist "%CMAKE_CPACK_ROOT%" ( mkdir "%CMAKE_CPACK_ROOT%" || exit /b )

call :PARENT_DIR "%%CMAKE_BUILD_DIR%%"
if not defined PARENT_DIR (
  echo.%~nx0: error: parent directory of the CMAKE_BUILD_DIR does not exist "%CMAKE_BUILD_DIR%".
  exit /b 10
)

call :PARENT_DIR "%%CMAKE_BIN_DIR%%"
if not defined PARENT_DIR (
  echo.%~nx0: error: parent directory of the CMAKE_BIN_DIR does not exist "%CMAKE_BIN_DIR%".
  exit /b 11
)

call :PARENT_DIR "%%CMAKE_LIB_DIR%%"
if not defined PARENT_DIR (
  echo.%~nx0: error: parent directory of the CMAKE_LIB_DIR does not exist "%CMAKE_LIB_DIR%".
  exit /b 12
)

call :PARENT_DIR "%%CMAKE_INSTALL_ROOT%%"
if not defined PARENT_DIR (
  echo.%~nx0: error: parent directory of the CMAKE_INSTALL_ROOT does not exist "%CMAKE_INSTALL_ROOT%".
  exit /b 13
)

call :PARENT_DIR "%%CMAKE_CPACK_DIR%%"
if not defined PARENT_DIR (
  echo.%~nx0: error: parent directory of the CMAKE_CPACK_DIR does not exist "%CMAKE_CPACK_DIR%".
  exit /b 14
)

rem return predefined variables
(
  endlocal
  set "CMAKE_BUILD_DIR=%CMAKE_BUILD_DIR%"
  set "CMAKE_BIN_DIR=%CMAKE_BIN_DIR%"
  set "CMAKE_LIB_DIR=%CMAKE_LIB_DIR%"
  set "CMAKE_CPACK_DIR=%CMAKE_CPACK_DIR%"
)

if not exist "%CMAKE_BUILD_DIR%" ( mkdir "%CMAKE_BUILD_DIR%" || exit /b )
if not exist "%CMAKE_BIN_DIR%" ( mkdir "%CMAKE_BIN_DIR%" || exit /b )
if not exist "%CMAKE_LIB_DIR%" ( mkdir "%CMAKE_LIB_DIR%" || exit /b )
if not exist "%CMAKE_CPACK_DIR%" ( mkdir "%CMAKE_CPACK_DIR%" || exit /b )

exit /b 0

:PARENT_DIR
set "PARENT_DIR="
if "%~1" == "" exit /b 255
set "DIR=%~dpf1"
set "PARENT_DIR=%~dp1"
if not exist "%PARENT_DIR%" (
  set "PARENT_DIR="
  exit /b 128
)
rem check on drive root
if /i "%DIR%" == "%PARENT_DIR%" (
  set "PARENT_DIR="
  exit /b 128
)
exit /b 0