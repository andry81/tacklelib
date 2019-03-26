@echo off

setlocal

set "OPTIONAL_COMPARE=%~1"
set "VARS_SYSTEM_FILE_IN=%~2"
set "VARS_SYSTEM_FILE=%~3"
set "VARS_USER_FILE_IN=%~4"
set "VARS_USER_FILE=%~5"

if not defined OPTIONAL_COMPARE set OPTIONAL_COMPARE=0

if not exist "%VARS_SYSTEM_FILE_IN%" (
  echo.%~nx0: error: VARS_SYSTEM_FILE_IN does not exist: "%VARS_SYSTEM_FILE_IN%".
  exit /b 1
) >&2

if %OPTIONAL_COMPARE% EQU 0 if not exist "%VARS_SYSTEM_FILE%" (
  echo.%~nx0: error: VARS_SYSTEM_FILE does not exist: "%VARS_SYSTEM_FILE%".
  exit /b 2
) >&2

if not exist "%VARS_USER_FILE_IN%" (
  echo.%~nx0: error: VARS_USER_FILE_IN does not exist: "%VARS_USER_FILE_IN%".
  exit /b 3
) >&2

if %OPTIONAL_COMPARE% EQU 0 if not exist "%VARS_USER_FILE%" (
  echo.%~nx0: error: VARS_USER_FILE does not exist: "%VARS_USER_FILE%".
  exit /b 4
) >&2

rem must be not empty to avoid bug in the parser of the if expression around `<var>:~` expression
set "VARS_SYSTEM_FILE_IN_VER_LINE=."
set "VARS_SYSTEM_FILE_VER_LINE=."

if exist "%VARS_SYSTEM_FILE_IN%" if exist "%VARS_SYSTEM_FILE%" (
  rem Test input and output files on version equality, otherwise we must stop and warn the user to merge the changes by yourself!
  set /P VARS_SYSTEM_FILE_IN_VER_LINE=<"%VARS_SYSTEM_FILE_IN%"
  set /P VARS_SYSTEM_FILE_VER_LINE=<"%VARS_SYSTEM_FILE%"
)

if exist "%VARS_SYSTEM_FILE_IN%" if exist "%VARS_SYSTEM_FILE%" (
  if /i "%VARS_SYSTEM_FILE_IN_VER_LINE:~0,12%" == "#%%%% version:" (
    if not "%VARS_SYSTEM_FILE_IN_VER_LINE:~13%" == "%VARS_SYSTEM_FILE_VER_LINE:~13%" (
      echo.%~nx0: error: version of "%VARS_SYSTEM_FILE_IN%" is not equal to version of "%VARS_SYSTEM_FILE%", user must merge changes by yourself!
      exit /b 10
    ) >&2
  )
)

rem must be not empty to avoid bug in the parser of the if expression around `<var>:~` expression
set "VARS_USER_FILE_IN_VER_LINE=."
set "VARS_USER_FILE_VER_LINE=."

if exist "%VARS_USER_FILE_IN%" if exist "%VARS_USER_FILE%" (
  rem Test input and output files on version equality, otherwise we must stop and warn the user to merge the changes by yourself!
  set /P VARS_USER_FILE_IN_VER_LINE=<"%VARS_USER_FILE_IN%"
  set /P VARS_USER_FILE_VER_LINE=<"%VARS_USER_FILE%"
)

if exist "%VARS_USER_FILE_IN%" if exist "%VARS_USER_FILE%" (
  if /i "%VARS_USER_FILE_IN_VER_LINE:~0,12%" == "#%%%% version:" (
    if not "%VARS_USER_FILE_IN_VER_LINE:~13%" == "%VARS_USER_FILE_VER_LINE:~13%" (
      echo.%~nx0: error: version of "%VARS_USER_FILE_IN%" is not equal to version of "%VARS_USER_FILE%", user must merge changes by yourself!
      exit /b 20
    ) >&2
  )
)

exit /b 0
