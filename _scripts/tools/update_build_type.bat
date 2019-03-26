@echo off

setlocal

rem convert abbrivated build type name to complete build type name
set CONFIG_ABBR_TYPE_INDEX=0
for %%i in (%CMAKE_CONFIG_ABBR_TYPES:;= %) do (
  if "%%i" == "%CMAKE_BUILD_TYPE%" (
    call :GET_CMAKE_BUILD_TYPE_BY_INDEX "%%CONFIG_ABBR_TYPE_INDEX%%"
    goto CMAKE_CONFIG_ABBR_TYPES_END
  )
  set /A CONFIG_ABBR_TYPE_INDEX+=1
)

goto CMAKE_CONFIG_ABBR_TYPES_END

:GET_CMAKE_BUILD_TYPE_BY_INDEX
set CONFIG_TYPE_INDEX=0
for %%j in (%CMAKE_CONFIG_TYPES:;= %) do (
  if "%CONFIG_ABBR_TYPE_INDEX%" EQU "%CONFIG_TYPE_INDEX%" (
    set "CMAKE_BUILD_TYPE=%%j"
    exit /b 0
  )
  set /A CONFIG_TYPE_INDEX+=1
)
exit /b 1

:CMAKE_CONFIG_ABBR_TYPES_END
(
  endlocal
  set "CMAKE_BUILD_TYPE=%CMAKE_BUILD_TYPE%"
)

exit /b 0
