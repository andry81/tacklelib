@echo off

call :CANONICAL_PATH PROJECT_ROOT "%%~dp0..\.."
call :CANONICAL_PATH TESTS_ROOT "%%PROJECT_ROOT%%/cmake_tests"

rem reset last error level
exit /b 0

:CANONICAL_PATH
set "%~1=%~dpf2"
call set "%%~1=%%%~1:\=/%%"
exit /b 0
