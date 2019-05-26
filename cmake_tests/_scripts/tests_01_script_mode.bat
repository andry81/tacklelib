@echo off

setlocal

call "%%~dp0__init__.bat" || goto :EOF

call :CMD cmake ^
  "-DCMAKE_MODULE_PATH=%%TESTS_ROOT%%;%%PROJECT_ROOT%%/cmake" ^
  "-DPROJECT_ROOT=%%PROJECT_ROOT%%" ^
  "-DTESTS_ROOT=%%TESTS_ROOT%%" ^
  "-DTACKLELIB_TESTLIB_TESTSCRIPT_FILE=%%TESTS_ROOT%%/%%~n0.cmake" ^
  "-DTACKLELIB_TESTLIB_ROOT=%%PROJECT_ROOT%%/cmake/tacklelib/testlib" ^
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
