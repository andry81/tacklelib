# include guard to speedup inclusion
if (NOT DEFINED TESTMODULE_INCLUDE_DEFINED)
set(TESTMODULE_INCLUDE_DEFINED 1)

include(ReturnCodeFile)
include(Eval)

if (NOT CMAKE_TESTMODULE_RETCODE_DIR OR NOT IS_DIRECTORY "${CMAKE_TESTMODULE_RETCODE_DIR}")
  message(FATAL_ERROR "CMAKE_TESTMODULE_RETCODE_DIR variable must be defined externally before include this module: CMAKE_TESTMODULE_RETCODE_DIR=`${CMAKE_TESTMODULE_RETCODE_DIR}`")
endif()

set(TESTMODULE_INITED 0)

function(TestModule_Init)
  SetReturnCodeToFile("${CMAKE_TESTMODULE_RETCODE_DIR}" -1) # init the default return code
  set(TESTMODULE_INITED 1 PARENT_SCOPE)
  set(TESTMODULE_RETCODE -1 PARENT_SCOPE)
  set(TESTCASE_RETCODE -1 PARENT_SCOPE)
endfunction()

function(TestModule_Exit)
  SetReturnCodeToFile("${CMAKE_TESTMODULE_RETCODE_DIR}" "${TESTMODULE_RETCODE}") # save the module last return code
endfunction()

macro(TestModule_RunTestCases)
  TestModule_Init()

  foreach(test_func ${ARGN})
    Eval("
if (NOT TESTS_ROOT OR NOT IS_DIRECTORY \"$\\{TESTS_ROOT}\")
  message(FATAL_ERROR \"TESTS_ROOT variable must be defained externally before include this module: TESTS_ROOT=`$\\{TESTS_ROOT}`\")
endif()

if (NOT EXISTS \"${CMAKE_CURRENT_LIST_FILE}\" OR IS_DIRECTORY \"${CMAKE_CURRENT_LIST_FILE}\")
  message(FATAL_ERROR \"CMAKE_CURRENT_LIST_FILE path must exist before include this module: CMAKE_CURRENT_LIST_FILE=`${CMAKE_CURRENT_LIST_FILE}`\")
endif()

file(RELATIVE_PATH TESTMODULE_FILE \"$\\{TESTS_ROOT}\" \"${CMAKE_CURRENT_LIST_FILE}\")
set(TESTCASE_FUNC \"${test_func}\")
set(TESTCASE_RETCODE -1) # empty test cases always fail

${test_func}()

if (NOT TESTCASE_RETCODE)
  message(\"[   OK   ] `$\\{TESTMODULE_FILE}`: $\\{TESTCASE_FUNC}\")
else()
  message(\"[ FAILED ] `$\\{TESTMODULE_FILE}`: $\\{TESTCASE_FUNC}\")
endif()
")
  endforeach()

  TestModule_Exit()
endmacro()

macro(TestAssertTrue exp msg)
  if (NOT TESTMODULE_INITED)
    message(FATAL_ERROR "Test module process is not initialized properly, call to TestModule_Init to initialize the test module process")
  endif()

  if (${exp})
    # don't change return code in a failed state
    if (TESTMODULE_RETCODE EQUAL -1)
      # first time success return code
      set(TESTMODULE_RETCODE 0)
      set(TESTMODULE_RETCODE 0 PARENT_SCOPE)
    endif()
    if (TESTCASE_RETCODE EQUAL -1)
      # first time success return code
      set(TESTCASE_RETCODE 0)
      set(TESTCASE_RETCODE 0 PARENT_SCOPE)
    endif()
  else()
    message("[ ASSERT ] `${TESTMODULE_FILE}`: exp=`${exp}` msg=`${msg}`")
    set(TESTMODULE_RETCODE 1)
    set(TESTMODULE_RETCODE 1 PARENT_SCOPE)
    set(TESTCASE_RETCODE 1)
    set(TESTCASE_RETCODE 1 PARENT_SCOPE)
    return() # always return from a test case function on first fail
  endif()
endmacro()

endif()
