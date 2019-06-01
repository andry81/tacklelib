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

  if (NOT DEFINED TACKLELIB_TESTLIB_TEST_CASE_MATCH_FILTER_LIST)
    message(FATAL_ERROR "TACKLELIB_TESTLIB_TEST_CASE_MATCH_FILTER_LIST match filter must be defined before include this module")
  endif()

  file(RELATIVE_PATH TACKLELIB_TESTLIB_TESTMODULE_FILE_REL_PATH "${TESTS_ROOT}" "${TACKLELIB_TESTLIB_TESTMODULE_FILE}")
  tkl_testmodule_test_file_shortcut("${TACKLELIB_TESTLIB_TESTMODULE_FILE_REL_PATH}" TACKLELIB_TESTLIB_TESTMODULE_FILE_REL_PATH_SHORTCUT)

  set_property(GLOBAL PROPERTY "tkl::testlib::testmodule::file_rel_path_shortcut" "${TACKLELIB_TESTLIB_TESTMODULE_FILE_REL_PATH_SHORTCUT}")
  set_property(GLOBAL PROPERTY "tkl::testlib::testmodule::file_rel_path" "${TACKLELIB_TESTLIB_TESTMODULE_FILE_REL_PATH}")

  set_property(GLOBAL PROPERTY "tkl::testlib::test_case_match_filter" "${TACKLELIB_TESTLIB_TEST_CASE_MATCH_FILTER_LIST}")

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

  tkl_get_global_prop(TACKLELIB_TESTLIB_TEST_CASE_MATCH_FILTER_LIST "tkl::testlib::test_case_match_filter" 1)
  tkl_get_global_prop(TACKLELIB_TESTLIB_TESTMODULE_FILE_REL_PATH_SHORTCUT "tkl::testlib::testmodule::file_rel_path_shortcut" 1)

  set(test_case_eval_str "\
unset(test_case_func)
unset(last_eval_temp_dir_path)
unset(TACKLELIB_TESTLIB_TESTCASE_FUNC)

if (NOT \"@TACKLELIB_TESTLIB_TESTCASE_FUNC@\" STREQUAL \"\")
  tkl_testmodule_print_msg(\"[RUNNING ] `${TACKLELIB_TESTLIB_TESTMODULE_FILE_REL_PATH_SHORTCUT}`: @TACKLELIB_TESTLIB_TESTCASE_FUNC@...\")
endif()

tkl_set_global_prop_and_var(TACKLELIB_TESTLIB_TESTCASE_RETCODE \"tkl::testlib::testcase::retcode\" -1) # empty test cases always fail
tkl_set_global_prop_and_var(TACKLELIB_TESTLIB_TESTCASE_FUNC \"tkl::testlib::testcase::func\" \"@TACKLELIB_TESTLIB_TESTCASE_FUNC@\")

@TACKLELIB_TESTLIB_TESTCASE_FUNC@()

tkl_get_global_prop(TACKLELIB_TESTLIB_TESTCASE_RETCODE \"tkl::testlib::testcase::retcode\" 1)

if (NOT TACKLELIB_TESTLIB_TESTCASE_RETCODE)
  tkl_testmodule_print_msg(\"[   OK   ] `${TACKLELIB_TESTLIB_TESTMODULE_FILE_REL_PATH_SHORTCUT}`: @TACKLELIB_TESTLIB_TESTCASE_FUNC@\")
else()
  tkl_testmodule_print_msg(\"[ FAILED ] `${TACKLELIB_TESTLIB_TESTMODULE_FILE_REL_PATH_SHORTCUT}`: @TACKLELIB_TESTLIB_TESTCASE_FUNC@\")
endif()

tkl_testmodule_update_status()
")

  set_property(GLOBAL PROPERTY "tkl::testlib::testmodule::test_case_eval_str" "${test_case_eval_str}")

  if (TACKLELIB_TESTLIB_TEST_CASE_MATCH_FILTER_LIST STREQUAL "")
    foreach(test_case_func IN LISTS ARGN)
      tkl_get_global_prop(test_case_eval_str "tkl::testlib::testmodule::test_case_eval_str" 1)
      tkl_eval_begin("include.tmpl.cmake" "${test_case_eval_str}")
      unset(test_case_eval_str)
      set(TACKLELIB_TESTLIB_TESTCASE_FUNC "${test_case_func}")
      tkl_get_last_eval_include_dir_path(last_eval_temp_dir_path)
      configure_file("${last_eval_temp_dir_path}/include.tmpl.cmake" "${last_eval_temp_dir_path}/include.cmake" @ONLY)
      tkl_eval_end("include.tmpl.cmake" "${last_eval_temp_dir_path}/include.cmake")
    endforeach()
  else()
    foreach(test_case_func ${ARGN})
      set(is_exclusively_included 0)
      set(is_excluded 0)

      string(TOLOWER "${test_case_func}" test_case_func_c)

      foreach(TACKLELIB_TESTLIB_TEST_CASE_MATCH_FILTER IN LISTS TACKLELIB_TESTLIB_TEST_CASE_MATCH_FILTER_LIST)
        tkl_regex_to_lower(test_case_match_filter_c "${TACKLELIB_TESTLIB_TEST_CASE_MATCH_FILTER}")

        set(is_include_filter 1)
        if (NOT test_case_match_filter_c STREQUAL "")
          string(SUBSTRING "${test_case_match_filter_c}" 0 1 test_case_match_filter_prefix_char)
          if (test_case_match_filter_prefix_char STREQUAL "-")
            string(SUBSTRING "${test_case_match_filter_c}" 1 -1 test_case_match_filter_c)
            set(is_include_filter 0)
          elseif (test_case_match_filter_prefix_char STREQUAL "+")
            string(SUBSTRING "${test_case_match_filter_c}" 1 -1 test_case_match_filter_c)
          endif()
        endif()

        if (NOT is_exclusively_included AND is_include_filter AND "${test_case_func_c}" MATCHES "${test_case_match_filter_c}")
          set(is_exclusively_included 1)
        endif()

        if (NOT is_include_filter AND "${test_case_func_c}" MATCHES "${test_case_match_filter_c}")
          set(is_excluded 1)
          break()
        endif()
      endforeach()

      if (is_exclusively_included AND (NOT is_excluded))
        tkl_get_global_prop(test_case_eval_str "tkl::testlib::testmodule::test_case_eval_str" 1)
        tkl_eval_begin("include.tmpl.cmake" "${test_case_eval_str}")
        unset(test_case_eval_str)
        set(TACKLELIB_TESTLIB_TESTCASE_FUNC "${test_case_func}")
        tkl_get_last_eval_include_dir_path(last_eval_temp_dir_path)
        configure_file("${last_eval_temp_dir_path}/include.tmpl.cmake" "${last_eval_temp_dir_path}/include.cmake" @ONLY)
        tkl_eval_end("include.tmpl.cmake" "${last_eval_temp_dir_path}/include.cmake")
      endif()
    endforeach()
  endif()
endfunction()

# CAUTION:
#   Must be a function to:
#   1. Simplify and reduce the entire code (for example, in a function the
#      `${ARGV0}` no needs to be escaped in case of call a macro from a function,
#      when the escaping is a mandatory in case of a macro call from a macro:
#      https://gitlab.kitware.com/cmake/cmake/issues/19281 )
#
# Parameters:
#   `${ARGV0}` - expression
#   `${ARGV1}` - assertion message
#
function(tkl_test_assert_true) # WITH OUT ARGUMENTS!
  if (${ARGC} LESS 1})
    message(FATAL_ERROR "function must have at least 1 argument")
  endif()

  tkl_get_global_prop(TACKLELIB_TESTLIB_TESTMODULE_INITED "tkl::testlib::testmodule::inited" 1)

  if (NOT TACKLELIB_TESTLIB_TESTMODULE_INITED)
    message(FATAL_ERROR "Test module process is not initialized properly, call to `RunTestModule.cmake` to initialize and execute the test module process")
  endif()

  #message("if_exp=${ARGV0}")
  tkl_eval("\
if (${ARGV0})
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
      tkl_testmodule_print_msg("[ ASSERT ] `${TACKLELIB_TESTLIB_TESTMODULE_FILE_REL_PATH_SHORTCUT}`: ${TACKLELIB_TESTLIB_TESTCASE_FUNC}: if_exp=`${ARGV0}` msg=`${ARGV1}`")
    else()
      tkl_testmodule_print_msg("[ ASSERT ] `${TACKLELIB_TESTLIB_TESTMODULE_FILE_REL_PATH_SHORTCUT}`: if_exp=`${ARGV0}` msg=`${ARGV1}`")
    endif()
    tkl_set_global_prop_and_var(TACKLELIB_TESTLIB_TESTMODULE_RETCODE "tkl::testlib::testmodule::retcode" 1)
    return() # always return from a test case function on first fail
  endif()
endfunction()

endif()
