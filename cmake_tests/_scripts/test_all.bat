@echo off

setlocal

call "%%~dp0__init__/__init1__.bat" || exit /b

set /A NEST_LVL+=1


call :CMD cmake ^
  "-DCMAKE_MODULE_PATH=%%TESTS_ROOT%%;%%PROJECT_ROOT%%/cmake" ^
  "-DPROJECT_ROOT=%%PROJECT_ROOT%%" ^
  "-DTESTS_ROOT=%%TESTS_ROOT%%" ^
  "-DTACKLELIB_TESTLIB_TESTSCRIPT_FILE=%%TESTS_ROOT%%/%%~n0.cmake" ^
  "-DTACKLELIB_TESTLIB_ROOT=%%PROJECT_ROOT%%/cmake/tacklelib/testlib" ^
  -P ^
  "%%PROJECT_ROOT%%/cmake/tacklelib/testlib/tools/RunTestLib.cmake" ^
  %%* || goto EXIT

:EXIT
set LASTERROR=%ERRORLEVEL%

set /A NEST_LVL-=1

if %NEST_LVL%0 EQU 0 pause

exit /b %LASTERROR%

:CMD
echo.^>%*
(
  %*
)
exit /b
