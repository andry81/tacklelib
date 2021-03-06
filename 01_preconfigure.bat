@echo off

setlocal

call "%%~dp0__init__.bat" || exit /b

if %UAC_MODE%0 EQU 0 (
  rem request admin permissions
  set UAC_MODE=1
  call :CMD "%%CONTOOLS_ROOT%%\cmd_admin.lnk" /c "%%~dpf0" %%*
  exit /b
)

echo.1. Download the local third party project: `tacklelib--3dparty`: `https://sf.net/p/tacklelib/3dparty`.
echo 2. Read the instructions from the readme file in the downloaded project to checkout third party sources.
echo.3. Press any key to continue and select the `_src` subdirectory in the `tacklelib--3dparty` project as a third party catalog.

call "%%CONTOOLS_ROOT%%/std/pause.bat"

for /F "usebackq eol=	 tokens=* delims=" %%i in (`@"%UTILITY_ROOT%/contools/wxFileDialog.exe" "" "%CONFIGURE_ROOT%" "Select the third party catalog to link with..." -de`) do set "_3DPARTY_ROOT=%%i"

if not exist "%_3DPARTY_ROOT%" (
  if not defined _3DPARTY_ROOT (
    echo.error: %~nx0: third party catalog is not selected.
  ) else (
    echo.error: %~nx0: third party catalog does not exist: "%_3DPARTY_ROOT%".
  )
  call "%%CONTOOLS_ROOT%%/std/pause.bat"
  exit /b 255
) >&2

call :CREATE_DIR_LINK "%%CONFIGURE_ROOT%%\_3dparty" "%%_3DPARTY_ROOT%%"

rem call :CREATE_DIR_LINK "%%CONFIGURE_ROOT%%\_scripts" "%%CONFIGURE_ROOT%%\_3dparty\utility\tacklelib\tacklelib\_scripts"
rem call :CREATE_DIR_LINK "%%CONFIGURE_ROOT%%\cmake" "%%CONFIGURE_ROOT%%\_3dparty\utility\tacklelib\tacklelib\cmake"

call "%%CONTOOLS_ROOT%%/std/pause.bat"

exit /b

:CREATE_DIR_LINK
set "MKLINK_CMD=mklink /D"
call :MKLINK %%*
exit /b

:CREATE_FILE_LINK
set "MKLINK_CMD=mklink"
call :MKLINK %%*
exit /b

:MKLINK
set "LINK_FROM=%~f1"
set "LINK_TO=%~f2"

if exist "%LINK_FROM%" exit /b 0

call :CMD %%MKLINK_CMD%% "%%LINK_FROM%%" "%%LINK_TO%%"
if exist "%LINK_FROM%" (
  echo."%LINK_FROM%" -^> "%LINK_TO%"
) else (
  echo.%~nx0%: error: could not create link: "%LINK_FROM%" -^> "%LINK_TO%"
  exit /b 255
) >&2

exit /b 0

:CMD
echo.^>%*
(%*)
exit /b
