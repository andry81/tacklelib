@echo off

setlocal

call "%%~dp0__init__.bat" || goto :EOF

set "TACKLELIB_TESTLIB_TESTSCRIPT_FILE=%~n0"

call :CMD cmake ^
  "-DCMAKE_MODULE_PATH=%%TESTS_ROOT%%;%%PROJECT_ROOT%%/cmake" ^
  "-DPROJECT_ROOT=%%PROJECT_ROOT%%" ^
  "-DTESTS_ROOT=%%TESTS_ROOT%%" ^
  "-DTACKLELIB_TESTLIB_TESTSCRIPT_FILE=%%TACKLELIB_TESTLIB_TESTSCRIPT_FILE%%" ^
  -P ^
  "%%PROJECT_ROOT%%/cmake/tacklelib/testlib/tools/RunTestLib.cmake" ^
  %%*
pause
exit /b

:CMD
echo.^>%*
(
  %*
)
exit /b
