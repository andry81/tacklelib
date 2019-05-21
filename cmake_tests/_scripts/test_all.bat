@echo off

setlocal

call "%%~dp0__init__.bat" || goto :EOF

set "TEST_SCRIPT_FILE_NAME=%~n0"

call :CMD cmake ^
  "-DCMAKE_MODULE_PATH=%%TESTS_ROOT%%;%%PROJECT_ROOT%%/cmake" ^
  "-DPROJECT_ROOT=%%PROJECT_ROOT%%" ^
  "-DTESTS_ROOT=%%TESTS_ROOT%%" ^
  "-DTEST_SCRIPT_FILE_NAME=%%TEST_SCRIPT_FILE_NAME%%" ^
  -P "%%TESTS_ROOT%%/%%TEST_SCRIPT_FILE_NAME%%.cmake" ^
  %%*
pause
exit /b

:CMD
echo.^>%*
(
  %*
)
exit /b
