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
  # CAUTION:
  #   Must use global property here to avoid accidental misuse, because a variable existence would depend on a function context.
  #
  tkl_get_global_prop(TACKLELIB_TESTLIB_TESTMODULE_INITED "tkl::testlib::testmodule::inited" 1)

  # single initialization
  if (TACKLELIB_TESTLIB_TESTMODULE_INITED)
    return()
  endif()

  # initialize properties from global variables
  set_property(GLOBAL PROPERTY "tkl::testlib::testproc::retcode_dir" "${TACKLELIB_TESTLIB_TESTPROC_RETCODE_DIR}")
  set_property(GLOBAL PROPERTY "tkl::testlib::testproc::index" "${TACKLELIB_TESTLIB_TESTPROC_INDEX}")

  tkl_set_ret_code_to_file_dir("${TACKLELIB_TESTLIB_TESTPROC_RETCODE_DIR}" -1) # init the default return code
  set_property(GLOBAL PROPERTY "tkl::testlib::testmodule::retcode" -1)
  set_property(GLOBAL PROPERTY "tkl::testlib::testcase::retcode" -1)

  set_property(GLOBAL PROPERTY "tkl::testlib::testcase::func" "")

  if (NOT DEFINED TESTS_ROOT OR NOT IS_DIRECTORY "${TESTS_ROOT}")
    message(FATAL_ERROR "TESTS_ROOT variable must be defained externally before include this module: TESTS_ROOT=`${TESTS_ROOT}`")
  endif()

  if (NOT DEFINED TACKLELIB_TESTLIB_TESTMODULE_FILE OR NOT EXISTS "${TACKLELIB_TESTLIB_TESTMODULE_FILE}" OR IS_DIRECTORY "${TACKLELIB_TESTLIB_TESTMODULE_FILE}")
    message(FATAL_ERROR "TACKLELIB_TESTLIB_TESTMODULE_FILE file path must exist before include this module: TACKLELIB_TESTLIB_TESTMODULE_FILE=`${TACKLELIB_TESTLIB_TESTMODULE_FILE}`")
  endif()

  file(RELATIVE_PATH TACKLELIB_TESTLIB_TESTMODULE_FILE_REL_PATH "${TESTS_ROOT}" "${TACKLELIB_TESTLIB_TESTMODULE_FILE}")
  tkl_testmodule_test_file_shortcut("${TACKLELIB_TESTLIB_TESTMODULE_FILE_REL_PATH}" TACKLELIB_TESTLIB_TESTMODULE_FILE_REL_PATH_SHORTCUT)

  set_property(GLOBAL PROPERTY "tkl::testlib::testmodule::file_rel_path_shortcut" "${TACKLELIB_TESTLIB_TESTMODULE_FILE_REL_PATH_SHORTCUT}")
  set_property(GLOBAL PROPERTY "tkl::testlib::testmodule::file_rel_path" "${TACKLELIB_TESTLIB_TESTMODULE_FILE_REL_PATH}")

  # CAUTION:
  #   Must use global property here to avoid accidental misuse, because a variable existence would depend on a function context.
  #
  set_property(GLOBAL PROPERTY "tkl::testlib::testmodule::inited" 1)
endfunction()

# to update status of the cmake process
function(tkl_testmodule_update_status)
  tkl_get_global_prop(TACKLELIB_TESTLIB_TESTMODULE_INITED "tkl::testlib::testmodule::inited" 1)

  if (NOT TACKLELIB_TESTLIB_TESTMODULE_INITED)
    message(FATAL_ERROR "Test module process is not initialized properly, call to `RunTestModule.cmake` to initialize and execute the test module process")
  endif()

  tkl_get_global_prop(TACKLELIB_TESTLIB_TESTMODULE_RETCODE "tkl::testlib::testmodule::retcode" 1)

  tkl_set_ret_code_to_file_dir("${TACKLELIB_TESTLIB_TESTPROC_RETCODE_DIR}" "${TACKLELIB_TESTLIB_TESTMODULE_RETCODE}") # save the module last return code
endfunction()

function(tkl_testmodule_print_msg msg)
  tkl_get_global_prop(TACKLELIB_TESTLIB_TESTMODULE_INITED "tkl::testlib::testmodule::inited" 1)

  if (NOT TACKLELIB_TESTLIB_TESTMODULE_INITED)
    message(FATAL_ERROR "Test module process is not initialized properly, call to `RunTestModule.cmake` to initialize and execute the test module process")
  endif()

  message("${msg}")
endfunction()

function(tkl_testmodule_test_file_shortcut test_file_path out_var)
  # cut off trailing `.test.*`
  string(TOLOWER "${test_file_path}" test_file_path_c)
  string(REGEX REPLACE "\\.test\\.cmake\$" "" test_file_path_shortcut_c "${test_file_path_c}")
  string(LENGTH "${test_file_path_c}" test_file_path_c_len)
  string(LENGTH "${test_file_path_shortcut_c}" test_file_path_shortcut_c_len)
  if (NOT test_file_path_c_len EQUAL test_file_path_shortcut_c_len)
    string(SUBSTRING "${test_file_path}" 0 ${test_file_path_shortcut_c_len} test_file_path_shortcut)
  else()
    set(test_file_path_shortcut "${test_file_path}")
  endif()

  set(${out_var} "${test_file_path_shortcut}" PARENT_SCOPE)
endfunction()

function(tkl_testmodule_run_test_cases)
  tkl_get_global_prop(TACKLELIB_TESTLIB_TESTMODULE_INITED "tkl::testlib::testmodule::inited" 1)

  if (NOT TACKLELIB_TESTLIB_TESTMODULE_INITED)
    message(FATAL_ERROR "Test module process is not initialized properly, call to `RunTestModule.cmake` to initialize and execute the test module process")
  endif()

  tkl_get_global_prop(TACKLELIB_TESTLIB_TESTMODULE_FILE_REL_PATH_SHORTCUT "tkl::testlib::testmodule::file_rel_path_shortcut" 1)

  foreach(test_func ${ARGN})
    tkl_eval("\
tkl_set_global_prop_and_var(TACKLELIB_TESTLIB_TESTCASE_RETCODE \"tkl::testlib::testcase::retcode\" -1) # empty test cases always fail
tkl_set_global_prop_and_var(TACKLELIB_TESTLIB_TESTCASE_FUNC \"tkl::testlib::testcase::func\" \"${test_func}\")

${test_func}()

tkl_get_global_prop(TACKLELIB_TESTLIB_TESTCASE_RETCODE \"tkl::testlib::testcase::retcode\" 1)

if (NOT TACKLELIB_TESTLIB_TESTCASE_RETCODE)
  tkl_testmodule_print_msg(\"[   OK   ] `${TACKLELIB_TESTLIB_TESTMODULE_FILE_REL_PATH_SHORTCUT}`: \${test_func}\")
else()
  tkl_testmodule_print_msg(\"[ FAILED ] `${TACKLELIB_TESTLIB_TESTMODULE_FILE_REL_PATH_SHORTCUT}`: \${test_func}\")
endif()

tkl_testmodule_update_status()
")
  endforeach()
endfunction()

# CAUTION:
#   Must be a function to:
#   1. Simplify and reduce the entire code (for example, in a function the
#      `${if_exp}` no needs to be escaped in case of call a macro from a function,
#      when the escaping is a mandatory in case of a macro call from a macro:
#      https://gitlab.kitware.com/cmake/cmake/issues/19281 )
#
function(tkl_test_assert_true if_exp msg)
  tkl_get_global_prop(TACKLELIB_TESTLIB_TESTMODULE_INITED "tkl::testlib::testmodule::inited" 1)

  if (NOT TACKLELIB_TESTLIB_TESTMODULE_INITED)
    message(FATAL_ERROR "Test module process is not initialized properly, call to `RunTestModule.cmake` to initialize and execute the test module process")
  endif()

  #message("if_exp=${if_exp}")
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
    tkl_get_global_prop(TACKLELIB_TESTLIB_TESTMODULE_FILE_REL_PATH_SHORTCUT "tkl::testlib::testmodule::file_rel_path_shortcut" 1)
    tkl_get_global_prop(TACKLELIB_TESTLIB_TESTCASE_FUNC "tkl::testlib::testcase::func" 1)

    if (NOT TACKLELIB_TESTLIB_TESTCASE_FUNC STREQUAL "")
      tkl_testmodule_print_msg("[ ASSERT ] `${TACKLELIB_TESTLIB_TESTMODULE_FILE_REL_PATH_SHORTCUT}`: ${TACKLELIB_TESTLIB_TESTCASE_FUNC}: if_exp=`${if_exp}` msg=`${msg}`")
    else()
      tkl_testmodule_print_msg("[ ASSERT ] `${TACKLELIB_TESTLIB_TESTMODULE_FILE_REL_PATH_SHORTCUT}`: if_exp=`${if_exp}` msg=`${msg}`")
    endif()
    tkl_set_global_prop_and_var(TACKLELIB_TESTLIB_TESTMODULE_RETCODE "tkl::testlib::testmodule::retcode" 1)
    return() # always return from a test case function on first fail
  endif()
endfunction()

endif()
