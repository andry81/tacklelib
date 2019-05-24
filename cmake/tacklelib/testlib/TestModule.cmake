# inclusion guard for protection and speedup
if (NOT DEFINED TACKLELIB_TESTMODULE_INCLUDE_DEFINED)
set(TACKELIB_TESTMODULE_INCLUDE_DEFINED 1)

include(tacklelib/Std)
include(tacklelib/ReturnCodeFile)
include(tacklelib/Eval)

if (NOT DEFINED TACKLELIB_TESTLIB_TESTPROC_RETCODE_DIR OR NOT IS_DIRECTORY "${TACKLELIB_TESTLIB_TESTPROC_RETCODE_DIR}")
  message(FATAL_ERROR "TACKLELIB_TESTLIB_TESTPROC_RETCODE_DIR variable must be defined externally before include this module: TACKLELIB_TESTLIB_TESTPROC_RETCODE_DIR=`${TACKLELIB_TESTLIB_TESTPROC_RETCODE_DIR}`")
endif()
if (NOT DEFINED TACKLELIB_TESTLIB_TESTPROC_INDEX OR TACKLELIB_TESTLIB_TESTPROC_INDEX STREQUAL "")
  message(FATAL_ERROR "TACKLELIB_TESTLIB_TESTPROC_INDEX variable must be defined externally before include this module")
endif()

function(tkl_testmodule_init)
  # initialize properties from global variables
  set_property(GLOBAL PROPERTY "tkl::testlib::testproc::retcode_dir" "${TACKLELIB_TESTLIB_TESTPROC_RETCODE_DIR}")
  set_property(GLOBAL PROPERTY "tkl::testlib::testproc::index" "${TACKLELIB_TESTLIB_TESTPROC_INDEX}")

  tkl_set_ret_code_to_file_dir("${TACKLELIB_TESTLIB_TESTPROC_RETCODE_DIR}" -1) # init the default return code
  set_property(GLOBAL PROPERTY "tkl::testlib::testmodule::retcode" -1)
  set_property(GLOBAL PROPERTY "tkl::testlib::testcase::retcode" -1)

  set_property(GLOBAL PROPERTY "tkl::testlib::testmodule::inited" 1)
endfunction()

# to update status of the cmake process
function(tkl_testmodule_update_status)
  tkl_get_global_prop(TACKLELIB_TESTLIB_TESTMODULE_INITED "tkl::testlib::testmodule::inited" 0)

  if (NOT TACKLELIB_TESTLIB_TESTMODULE_INITED)
    message(FATAL_ERROR "Test module process is not initialized properly, call to `tkl_testmodule_init` to initialize the test module process")
  endif()

  tkl_get_global_prop(TACKLELIB_TESTLIB_TESTMODULE_RETCODE "tkl::testlib::testmodule::retcode" 1)

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

file(RELATIVE_PATH TACKLELIB_TESTLIB_TESTMODULE_FILE \"$\\{TESTS_ROOT}\" \"${CMAKE_CURRENT_LIST_FILE}\")
set_property(GLOBAL PROPERTY \"tkl::testlib::testmodule::file\" \"\${TACKLELIB_TESTLIB_TESTMODULE_FILE}\") # empty test cases always fail

tkl_set_global_prop_and_var(TACKLELIB_TESTLIB_TESTCASE_FUNC \"tkl::testlib::testcase::func\" \"${test_func}\")

tkl_set_global_prop_and_var(TACKLELIB_TESTLIB_TESTCASE_RETCODE \"tkl::testlib::testcase::retcode\" -1) # empty test cases always fail

${test_func}()

tkl_get_global_prop(TACKLELIB_TESTLIB_TESTCASE_RETCODE \"tkl::testlib::testcase::retcode\" 1)

if (NOT TACKLELIB_TESTLIB_TESTCASE_RETCODE)
  message(\"[   OK   ] `\${TACKLELIB_TESTLIB_TESTMODULE_FILE}`: \${TACKLELIB_TESTLIB_TESTCASE_FUNC}\")
else()
  message(\"[ FAILED ] `\${TACKLELIB_TESTLIB_TESTMODULE_FILE}`: \${TACKLELIB_TESTLIB_TESTCASE_FUNC}\")
endif()
")
  endforeach()

  tkl_testmodule_update_status()
endmacro()

# CAUTION:
#   Must be a function to:
#   1. Simplify and reduce the entire code (for example, in a function the
#      `${if_exp}` no needs to be escaped in case of call a macro from a function,
#      when the escaping is a mandatory in case of a macro call from a macro:
#      https://gitlab.kitware.com/cmake/cmake/issues/19281 )
#
function(tkl_test_assert_true if_exp msg)
  tkl_get_global_prop(TACKLELIB_TESTLIB_TESTMODULE_INITED "tkl::testlib::testmodule::inited" 0)

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

  set_property(GLOBAL PROPERTY "tkl::testlib::testcase::retcode" "${TACKLELIB_TESTLIB_TESTCASE_RETCODE}")

  tkl_get_global_prop(TACKLELIB_TESTLIB_TESTMODULE_RETCODE "tkl::testlib::testmodule::retcode" 1)

  if (NOT TACKLELIB_TESTLIB_TESTCASE_RETCODE)
    # set module success on at least one and first assert call (a module must fail if no one test assert have has used)
    if (TACKLELIB_TESTLIB_TESTMODULE_RETCODE EQUAL -1)
      # first time success return code
      tkl_set_global_prop_and_var(TACKLELIB_TESTLIB_TESTMODULE_RETCODE "tkl::testlib::testmodule::retcode" 0)
    endif()
  else()
    tkl_get_global_prop(TACKLELIB_TESTLIB_TESTMODULE_FILE "tkl::testlib::testmodule::file" 1)
    tkl_get_global_prop(TACKLELIB_TESTLIB_TESTCASE_FUNC "tkl::testlib::testcase::func" 1)

    message("[ ASSERT ] `\${TACKLELIB_TESTLIB_TESTMODULE_FILE}`: ${TACKLELIB_TESTLIB_TESTCASE_FUNC}: if_exp=`${if_exp}` msg=`${msg}`")
    tkl_set_global_prop_and_var(TACKLELIB_TESTLIB_TESTMODULE_RETCODE "tkl::testlib::testmodule::retcode" 1)
    return() # always return from a test case function on first fail
  endif()
endfunction()

endif()
