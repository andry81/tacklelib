# inclusion guard for protection and speedup
if (NOT DEFINED TACKLELIB_TESTMODULE_INCLUDE_DEFINED)
set(TACKELIB_TESTMODULE_INCLUDE_DEFINED 1)

include(tacklelib/ReturnCodeFile)
include(tacklelib/Eval)

if (NOT TACKLELIB_TESTLIB_TESTPROC_RETCODE_DIR OR NOT IS_DIRECTORY "${TACKLELIB_TESTLIB_TESTPROC_RETCODE_DIR}")
  message(FATAL_ERROR "TACKLELIB_TESTLIB_TESTPROC_RETCODE_DIR variable must be defined externally before include this module: TACKLELIB_TESTLIB_TESTPROC_RETCODE_DIR=`${TACKLELIB_TESTLIB_TESTPROC_RETCODE_DIR}`")
endif()

set(TACKLELIB_TESTLIB_TESTMODULE_INITED 0)

function(tkl_testmodule_init)
  tkl_set_ret_code_to_file_dir("${TACKLELIB_TESTLIB_TESTPROC_RETCODE_DIR}" -1) # init the default return code
  set(TACKLELIB_TESTLIB_TESTMODULE_INITED 1 PARENT_SCOPE)
  set(TACKLELIB_TESTLIB_TESTMODULE_RETCODE -1 PARENT_SCOPE)
  set(TACKLELIB_TESTLIB_TESTCASE_RETCODE -1 PARENT_SCOPE)
endfunction()

function(tkl_testmodule_exit)
  tkl_set_ret_code_to_file_dir("${TACKLELIB_TESTLIB_TESTPROC_RETCODE_DIR}" "${TACKLELIB_TESTLIB_TESTMODULE_RETCODE}") # save the module last return code
endfunction()

macro(tkl_testmodule_run_test_cases)
  tkl_testmodule_init()

  foreach(test_func ${ARGN})
    tkl_eval("\
if (NOT TESTS_ROOT OR NOT IS_DIRECTORY \"$\\{TESTS_ROOT}\")
  message(FATAL_ERROR \"TESTS_ROOT variable must be defained externally before include this module: TESTS_ROOT=`$\\{TESTS_ROOT}`\")
endif()

if (NOT EXISTS \"${CMAKE_CURRENT_LIST_FILE}\" OR IS_DIRECTORY \"${CMAKE_CURRENT_LIST_FILE}\")
  message(FATAL_ERROR \"CMAKE_CURRENT_LIST_FILE path must exist before include this module: CMAKE_CURRENT_LIST_FILE=`${CMAKE_CURRENT_LIST_FILE}`\")
endif()

file(RELATIVE_PATH TESTMODULE_FILE \"$\\{TESTS_ROOT}\" \"${CMAKE_CURRENT_LIST_FILE}\")
set(TACKLELIB_TESTLIB_TESTCASE_FUNC \"${test_func}\")
set(TACKLELIB_TESTLIB_TESTCASE_RETCODE -1) # empty test cases always fail

${test_func}()

if (NOT TACKLELIB_TESTLIB_TESTCASE_RETCODE)
  message(\"[   OK   ] `$\\{TESTMODULE_FILE}`: $\\{TACKLELIB_TESTLIB_TESTCASE_FUNC}\")
else()
  message(\"[ FAILED ] `$\\{TESTMODULE_FILE}`: $\\{TACKLELIB_TESTLIB_TESTCASE_FUNC}\")
endif()
")
  endforeach()

  tkl_testmodule_exit()
endmacro()

macro(tkl_test_assert_true if_exp msg)
  if (NOT TACKLELIB_TESTLIB_TESTMODULE_INITED)
    message(FATAL_ERROR "Test module process is not initialized properly, call to `tkl_testmodule_init` to initialize the test module process")
  endif()

  tkl_eval("\
if (${if_exp})
  set(TACKLELIB_TESTLIB_TESTCASE_RETCODE 0)
else()
  set(TACKLELIB_TESTLIB_TESTCASE_RETCODE 1)
endif()
")

  set(TACKLELIB_TESTLIB_TESTCASE_RETCODE "${TACKLELIB_TESTLIB_TESTCASE_RETCODE}" PARENT_SCOPE)

  if (NOT TACKLELIB_TESTLIB_TESTCASE_RETCODE)
    # set module success on at least one and first assert call (a module must fail if no one test assert have has used)
    if (TACKLELIB_TESTLIB_TESTMODULE_RETCODE EQUAL -1)
      # first time success return code
      set(TACKLELIB_TESTLIB_TESTMODULE_RETCODE 0)
      set(TACKLELIB_TESTLIB_TESTMODULE_RETCODE 0 PARENT_SCOPE)
    endif()
  else()
    message("[ ASSERT ] `${TESTMODULE_FILE}`: ${TACKLELIB_TESTLIB_TESTCASE_FUNC}: if_exp=`${if_exp}` msg=`${msg}`")
    set(TACKLELIB_TESTLIB_TESTMODULE_RETCODE 1)
    set(TACKLELIB_TESTLIB_TESTMODULE_RETCODE 1 PARENT_SCOPE)
    return() # always return from a test case function on first fail
  endif()
endmacro()

# to propogate nested function test case results to the parent scope
macro(tkl_testcase_return)
  set(TACKLELIB_TESTLIB_TESTCASE_RETCODE "${TACKLELIB_TESTLIB_TESTCASE_RETCODE}" PARENT_SCOPE)
  set(TACKLELIB_TESTLIB_TESTMODULE_RETCODE "${TACKLELIB_TESTLIB_TESTMODULE_RETCODE}" PARENT_SCOPE)
  return()
endmacro()

macro(tkl_testcase_return_if_failed)
  if (TACKLELIB_TESTLIB_TESTCASE_RETCODE)
    set(TACKLELIB_TESTLIB_TESTCASE_RETCODE "${TACKLELIB_TESTLIB_TESTCASE_RETCODE}" PARENT_SCOPE)
    set(TACKLELIB_TESTLIB_TESTMODULE_RETCODE "${TACKLELIB_TESTLIB_TESTMODULE_RETCODE}" PARENT_SCOPE)
    return()
  endif()
endmacro()

endif()
