# inclusion guard for protection and speedup
if (NOT DEFINED TACKLELIB_TESTMODULE_INCLUDE_DEFINED)
set(TACKLELIB_TESTMODULE_INCLUDE_DEFINED 1)

include(tacklelib/Std)
include(tacklelib/ReturnCodeFile)
include(tacklelib/ForwardArgs)
include(tacklelib/Eval)
include(tacklelib/SetVarsFromFiles)

function(tkl_testmodule_init)
  # CAUTION:
  #   Must use global property here to avoid accidental misuse, because a variable existence would depend on a function context.
  #
  tkl_get_global_prop(TACKLELIB_TESTLIB_TESTMODULE_INITED "tkl::testlib::testmodule::inited" 1)

  # single initialization
  if (TACKLELIB_TESTLIB_TESTMODULE_INITED)
    return()
  endif()

  if (NOT DEFINED TESTS_ROOT OR NOT IS_DIRECTORY "${TESTS_ROOT}")
    message(FATAL_ERROR "TESTS_ROOT variable must be defained externally to an existed directory path before include this module: TESTS_ROOT=`${TESTS_ROOT}`")
  endif()

  if (NOT DEFINED TACKLELIB_TESTLIB_TESTPROC_RETCODE_DIR OR NOT IS_DIRECTORY "${TACKLELIB_TESTLIB_TESTPROC_RETCODE_DIR}")
    message(FATAL_ERROR "TACKLELIB_TESTLIB_TESTPROC_RETCODE_DIR variable must be defined externally to an existed directory path before include this module: TACKLELIB_TESTLIB_TESTPROC_RETCODE_DIR=`${TACKLELIB_TESTLIB_TESTPROC_RETCODE_DIR}`")
  endif()
  if (NOT DEFINED TACKLELIB_TESTLIB_TESTPROC_INDEX OR TACKLELIB_TESTLIB_TESTPROC_INDEX STREQUAL "")
    message(FATAL_ERROR "TACKLELIB_TESTLIB_TESTPROC_INDEX variable must be defined externally before include this module")
  endif()
  if (NOT DEFINED TACKLELIB_TESTLIB_TESTMODULE_DIR OR NOT IS_DIRECTORY "${TACKLELIB_TESTLIB_TESTMODULE_DIR}")
    message(FATAL_ERROR "TACKLELIB_TESTLIB_TESTMODULE_DIR variable must be defined externally to an existed directory path before include this module: TACKLELIB_TESTLIB_TESTMODULE_DIR=`${TACKLELIB_TESTLIB_TESTMODULE_DIR}`")
  endif()
  if (NOT DEFINED TACKLELIB_TESTLIB_TESTMODULE_FILE OR NOT EXISTS "${TACKLELIB_TESTLIB_TESTMODULE_FILE}" OR IS_DIRECTORY "${TACKLELIB_TESTLIB_TESTMODULE_FILE}")
    message(FATAL_ERROR "TACKLELIB_TESTLIB_TESTMODULE_FILE variable must be defined externally to an existed file path before include this module: TACKLELIB_TESTLIB_TESTMODULE_FILE=`${TACKLELIB_TESTLIB_TESTMODULE_FILE}`")
  endif()
  if ("${TACKLELIB_TESTLIB_TESTMODULE_FILE_NAME_PREFIX}" STREQUAL "")
    message(FATAL_ERROR "TACKLELIB_TESTLIB_TESTMODULE_FILE_NAME_PREFIX variable must be defined externally to not empty test file name prefix without all extensions: TACKLELIB_TESTLIB_TESTMODULE_FILE_NAME_PREFIX=`${TACKLELIB_TESTLIB_TESTMODULE_FILE_NAME_PREFIX}`")
  endif()
  if ("${TACKLELIB_TESTLIB_TESTMODULE_FILE_NAME_EXT}" STREQUAL "")
    message(FATAL_ERROR "TACKLELIB_TESTLIB_TESTMODULE_FILE_NAME_EXT variable must be defined externally to not empty test file name with extension: TACKLELIB_TESTLIB_TESTMODULE_FILE_NAME_EXT=`${TACKLELIB_TESTLIB_TESTMODULE_FILE_NAME_EXT}`")
  endif()

  if (NOT DEFINED TACKLELIB_TESTLIB_TEST_CASE_MATCH_FILTER_LIST)
    message(FATAL_ERROR "TACKLELIB_TESTLIB_TEST_CASE_MATCH_FILTER_LIST match filter must be defined before include this module")
  endif()

  # initialize properties from global variables
  set_property(GLOBAL PROPERTY "tkl::testlib::testproc::retcode_dir" "${TACKLELIB_TESTLIB_TESTPROC_RETCODE_DIR}")
  set_property(GLOBAL PROPERTY "tkl::testlib::testproc::index" "${TACKLELIB_TESTLIB_TESTPROC_INDEX}")

  tkl_set_ret_code_to_file_dir("${TACKLELIB_TESTLIB_TESTPROC_RETCODE_DIR}" -1) # init the default return code
  set_property(GLOBAL PROPERTY "tkl::testlib::testmodule::retcode" -1)
  set_property(GLOBAL PROPERTY "tkl::testlib::testcase::retcode" -1)

  set_property(GLOBAL PROPERTY "tkl::testlib::testcase::func" "")

  file(RELATIVE_PATH TACKLELIB_TESTLIB_TESTMODULE_FILE_REL_PATH "${TESTS_ROOT}" "${TACKLELIB_TESTLIB_TESTMODULE_FILE}")
  tkl_testmodule_test_file_shortcut("${TACKLELIB_TESTLIB_TESTMODULE_FILE_REL_PATH}" TACKLELIB_TESTLIB_TESTMODULE_FILE_REL_PATH_SHORTCUT)

  set_property(GLOBAL PROPERTY "tkl::testlib::testmodule::file_rel_path_shortcut" "${TACKLELIB_TESTLIB_TESTMODULE_FILE_REL_PATH_SHORTCUT}")
  set_property(GLOBAL PROPERTY "tkl::testlib::testmodule::file_rel_path" "${TACKLELIB_TESTLIB_TESTMODULE_FILE_REL_PATH}")

  set_property(GLOBAL PROPERTY "tkl::testlib::test_case_match_filter" "${TACKLELIB_TESTLIB_TEST_CASE_MATCH_FILTER_LIST}")

  # load local TestModule configuration variables
  if (EXISTS "${TACKLELIB_TESTLIB_TESTMODULE_DIR}/${TACKLELIB_TESTLIB_TESTMODULE_FILE_NAME_PREFIX}.test.vars" AND
      NOT IS_DIRECTORY "${TACKLELIB_TESTLIB_TESTMODULE_DIR}/${TACKLELIB_TESTLIB_TESTMODULE_FILE_NAME_PREFIX}.test.vars")
    tkl_track_vars_begin()

    tkl_load_vars_from_files("${TACKLELIB_TESTLIB_TESTMODULE_DIR}/${TACKLELIB_TESTLIB_TESTMODULE_FILE_NAME_PREFIX}.test.vars")

    tkl_forward_changed_vars_to_parent_scope()
    tkl_track_vars_end()
  endif()

  # CAUTION:
  #   Must use global property here to avoid accidental misuse, because a variable existence would depend on a function context.
  #
  set_property(GLOBAL PROPERTY "tkl::testlib::testmodule::inited" 1)
endfunction()

# to update status of the cmake process
function(tkl_testmodule_update_status)
  tkl_get_global_prop(TACKLELIB_TESTLIB_TESTMODULE_INITED "tkl::testlib::testmodule::inited" 1)

  if (NOT TACKLELIB_TESTLIB_TESTMODULE_INITED)
    message(FATAL_ERROR "test module process is not initialized properly, call to `RunTestModule.cmake` to initialize and execute the test module process")
  endif()

  tkl_get_global_prop(TACKLELIB_TESTLIB_TESTMODULE_RETCODE "tkl::testlib::testmodule::retcode" 1)

  tkl_set_ret_code_to_file_dir("${TACKLELIB_TESTLIB_TESTPROC_RETCODE_DIR}" "${TACKLELIB_TESTLIB_TESTMODULE_RETCODE}") # save the module last return code

  unset(TACKLELIB_TESTLIB_TESTMODULE_RETCODE)
endfunction()

# raw test message
function(tkl_test_msg msg)
  tkl_get_global_prop(TACKLELIB_TESTLIB_TESTMODULE_INITED "tkl::testlib::testmodule::inited" 1)

  if (NOT TACKLELIB_TESTLIB_TESTMODULE_INITED)
    message(FATAL_ERROR "test module process is not initialized properly, call to `RunTestModule.cmake` to initialize and execute the test module process")
  endif()

#  if (CMAKE_MAJOR_VERSION GREATER 3 OR (CMAKE_MAJOR_VERSION EQUAL 3 AND CMAKE_MINOR_VERSION GREATER 14))
#    message(TRACE "${msg}")
#  else()
    message(STATUS "${msg}")  # to print to stdout
#  endif()
endfunction()

function(tkl_test_info_msg msg)
  tkl_test_msg("[  INFO  ] ${msg}")
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

macro(tkl_testmodule_begin_time_sec out_var)
  get_property(${out_var} GLOBAL PROPERTY "tkl::testlib::testmodule::begin_time_sec")
endmacro()

function(tkl_testmodule_time_check_point_sec out_var)
  tkl_time_sec(time_check_point_sec)
  tkl_testmodule_begin_time_sec(time_begin_sec)
  math(EXPR time_spent_sec ${time_check_point_sec}-${time_begin_sec})
  set(${out_var} ${time_spent_sec} PARENT_SCOPE)
endfunction()

function(tkl_testmodule_run_test_cases)
  tkl_get_global_prop(TACKLELIB_TESTLIB_TESTMODULE_INITED "tkl::testlib::testmodule::inited" 1)

  if (NOT TACKLELIB_TESTLIB_TESTMODULE_INITED)
    message(FATAL_ERROR "test module process is not initialized properly, call to `RunTestModule.cmake` to initialize and execute the test module process")
  endif()

  tkl_get_global_prop(TACKLELIB_TESTLIB_TEST_CASE_MATCH_FILTER_LIST "tkl::testlib::test_case_match_filter" 1)
  tkl_get_global_prop(TACKLELIB_TESTLIB_TESTMODULE_FILE_REL_PATH_SHORTCUT "tkl::testlib::testmodule::file_rel_path_shortcut" 1)

  set(test_case_eval_str "\
unset(test_case_func)
unset(last_eval_temp_dir_path)
unset(TACKLELIB_TESTLIB_TESTCASE_FUNC)

if (NOT \"@TACKLELIB_TESTLIB_TESTCASE_FUNC@\" STREQUAL \"\")
  tkl_test_msg(\"[RUNNING ] `${TACKLELIB_TESTLIB_TESTMODULE_FILE_REL_PATH_SHORTCUT}`: @TACKLELIB_TESTLIB_TESTCASE_FUNC@...\")
endif()

tkl_set_global_prop(. \"tkl::testlib::testcase::retcode\" -1) # empty test cases always fail
tkl_set_global_prop(. \"tkl::testlib::testcase::func\" \"@TACKLELIB_TESTLIB_TESTCASE_FUNC@\")

tkl_time_sec(TACKLELIB_TESTLIB_TESTMODULE_BEGIN_TIME_SEC)
set_property(GLOBAL PROPERTY \"tkl::testlib::testmodule::begin_time_sec\" \"\${TACKLELIB_TESTLIB_TESTMODULE_BEGIN_TIME_SEC}\")
unset(TACKLELIB_TESTLIB_TESTMODULE_BEGIN_TIME_SEC)

@TACKLELIB_TESTLIB_TESTCASE_FUNC@()

tkl_time_sec(TACKLELIB_TESTLIB_TESTMODULE_END_TIME_SEC)
tkl_get_global_prop(TACKLELIB_TESTLIB_TESTMODULE_BEGIN_TIME_SEC \"tkl::testlib::testmodule::begin_time_sec\" 0)

tkl_get_global_prop(TACKLELIB_TESTLIB_TESTCASE_RETCODE \"tkl::testlib::testcase::retcode\" 1)

math(EXPR TACKLELIB_TESTLIB_TESTMODULE_RUN_TIME_SEC \${TACKLELIB_TESTLIB_TESTMODULE_END_TIME_SEC}-\${TACKLELIB_TESTLIB_TESTMODULE_BEGIN_TIME_SEC})

if (NOT TACKLELIB_TESTLIB_TESTCASE_RETCODE)
  tkl_test_msg(\"[   OK   ] `${TACKLELIB_TESTLIB_TESTMODULE_FILE_REL_PATH_SHORTCUT}`: @TACKLELIB_TESTLIB_TESTCASE_FUNC@ (\${TACKLELIB_TESTLIB_TESTMODULE_RUN_TIME_SEC} sec)\")
else()
  tkl_test_msg(\"[ FAILED ] `${TACKLELIB_TESTLIB_TESTMODULE_FILE_REL_PATH_SHORTCUT}`: @TACKLELIB_TESTLIB_TESTCASE_FUNC@ (\${TACKLELIB_TESTLIB_TESTMODULE_RUN_TIME_SEC} sec)\")
endif()

unset(TACKLELIB_TESTLIB_TESTCASE_RETCODE)
unset(TACKLELIB_TESTLIB_TESTMODULE_END_TIME_SEC)
unset(TACKLELIB_TESTLIB_TESTMODULE_RUN_TIME_SEC)

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
      unset(TACKLELIB_TESTLIB_TESTCASE_FUNC)
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
        unset(TACKLELIB_TESTLIB_TESTCASE_FUNC)
        tkl_eval_end("include.tmpl.cmake" "${last_eval_temp_dir_path}/include.cmake")
      endif()
    endforeach()
  endif()
endfunction()

# This is table of raw string conversion:
#
# input          | output        || input         | output
# ---------------+---------------||---------------+---------------
# `\`            | `\\`          || `\\`          | `\\\\`
# `\\\`          | `\\\\\\`      || `\\\\`        | `\\\\\\\\`
# `\a`           | `\\a`         || `\\a`         | `\\\\a`
# `\\\a`         | `\\\\\\a`     || `\\\\a`       | `\\\\\\\\a`
# `\;`           | `\;`          || `\\;`         | `\\\;`
# `\\\;`         | `\\\\\;`      || `\\\\;`       | `\\\\\\\;`
# `$`            | `\$`          || `\\$`         | `\\\\$`
# `\\\$`         | `\\\\\\$`     || `\\\\$`       | `\\\\\\\\$`
#
function(tkl_escape_test_assert_string out_var in_str)
  set(encoded_value "")
  set(index 0)
  set(is_escaping 0)
  string(LENGTH "${in_str}" value_len)

  while (index LESS value_len)
    string(SUBSTRING "${in_str}" ${index} 1 char)
    if (NOT is_escaping)
      if (NOT char STREQUAL "\\")
        if (NOT char STREQUAL "\$")
          set(encoded_value "${encoded_value}${char}")
        else()
          set(encoded_value "${encoded_value}\\\$") # retain special control character escaping
        endif()
      else()
        set(is_escaping 1)
      endif()
    else()
      if (char STREQUAL ";")
        set(encoded_value "${encoded_value}\;")   # retain special control character escaping
        set(is_escaping 0)
      elseif (char STREQUAL "\$")
        set(encoded_value "${encoded_value}\\\$") # retain special control character escaping
        set(is_escaping 0)
      else()
        set(encoded_value "${encoded_value}\\\\")
        if (NOT char STREQUAL "\\")
          set(encoded_value "${encoded_value}${char}")
          set(is_escaping 0)
        endif()
      endif()
    endif()

    math(EXPR index "${index}+1")
  endwhile()

  if (is_escaping)
    set(encoded_value "${encoded_value}\\\\")
  endif()

  set(${out_var} "${encoded_value}" PARENT_SCOPE)
endfunction()

# Usage:
#   Special characters:
#     `\`   - escape sequence character
#     `\n`  - multiline separator
#   Escape examples:
#     `$\{...}` or `\${...}` - to insert a variable expression without expansion.
#     But the first method is better, as it can additionally bypass a macro
#     arguments expansion stage, when the second is can not.
#     Works for:
#       `tkl_eval*`
#       `tkl_test_assert_true`
#
#   NOTE:
#     In case of nested expressions you have to double escape it:
#     `$\\{...}` or `\\\${...}`
#
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
  if (${ARGC} LESS 1)
    message(FATAL_ERROR "function must have at least 1 argument")
  endif()

  tkl_get_global_prop(TACKLELIB_TESTLIB_TESTMODULE_INITED "tkl::testlib::testmodule::inited" 1)

  if (NOT TACKLELIB_TESTLIB_TESTMODULE_INITED)
    message(FATAL_ERROR "test module process is not initialized properly, call to `RunTestModule.cmake` to initialize and execute the test module process")
  endif()

  if (${ARGC} LESS 2)
    unset(ARGV1)
  endif()

  #message("if_exp=`${ARGV0}`")
  set_property(GLOBAL PROPERTY "tkl::testlib::testmodule::last_test_assert_true::args::exp" "${ARGV0}")

  if (DEFINED ARGV1)
    set_property(GLOBAL PROPERTY "tkl::testlib::testmodule::last_test_assert_true::args::msg" "${ARGV1}")
  else()
    set_property(GLOBAL PROPERTY "tkl::testlib::testmodule::last_test_assert_true::args::msg") # unset property
  endif()

  tkl_eval_begin("test_assert_true_exp.cmake" "")

  tkl_eval_append("test_assert_true_exp.cmake" "\
if (${ARGV0})
  set_property(GLOBAL PROPERTY \"tkl::testlib::testcase::retcode\" 0)
else()
  set_property(GLOBAL PROPERTY \"tkl::testlib::testcase::retcode\" 1)
endif()
")

#  message("=")
#  tkl_print_ARGVn()

  # builtin arguments can interfere with the assert expression...

  # switch to special ARGVn stack
  tkl_use_ARGVn_stack_begin("tkl::testlib::testmodule")

  # save ARGV, ARGC, ARGV0..N variables from this scope
  tkl_push_ARGVn_to_stack_from_vars()

  # evaluating...
  tkl_eval_end("test_assert_true_exp.cmake" .)

  # restore ARGV, ARGC, ARGV0..N variables from this scope
  tkl_pop_ARGVn_from_stack()

  # switch to previous ARGVn stack
  tkl_use_ARGVn_stack_end()

#  tkl_print_ARGVn()
#  message("=")

  tkl_get_global_prop(TACKLELIB_TESTLIB_TESTCASE_RETCODE "tkl::testlib::testcase::retcode" 1)
  tkl_get_global_prop(TACKLELIB_TESTLIB_TESTMODULE_RETCODE "tkl::testlib::testmodule::retcode" 1)

  if (NOT TACKLELIB_TESTLIB_TESTCASE_RETCODE)
    # set module success on at least one and first assert call (a module must fail if no one test assert have has used)
    if (TACKLELIB_TESTLIB_TESTMODULE_RETCODE EQUAL -1)
      # first time success return code
      tkl_set_global_prop(TACKLELIB_TESTLIB_TESTMODULE_RETCODE "tkl::testlib::testmodule::retcode" 0)

      tkl_testmodule_update_status()
    endif()
  else()
    tkl_get_global_prop(TACKLELIB_TESTLIB_TESTMODULE_FILE_REL_PATH_SHORTCUT "tkl::testlib::testmodule::file_rel_path_shortcut" 1)
    tkl_get_global_prop(TACKLELIB_TESTLIB_TESTCASE_FUNC "tkl::testlib::testcase::func" 1)

    tkl_get_global_prop(arg_exp "tkl::testlib::testmodule::last_test_assert_true::args::exp" 1)
    tkl_get_global_prop(arg_msg "tkl::testlib::testmodule::last_test_assert_true::args::msg" 0)

    if (NOT TACKLELIB_TESTLIB_TESTCASE_FUNC STREQUAL "")
      tkl_test_msg("[ ASSERT ] `${TACKLELIB_TESTLIB_TESTMODULE_FILE_REL_PATH_SHORTCUT}`: `${TACKLELIB_TESTLIB_TESTCASE_FUNC}`:")
    else()
      tkl_test_msg("[ ASSERT ] `${TACKLELIB_TESTLIB_TESTMODULE_FILE_REL_PATH_SHORTCUT}`:")
    endif()
    tkl_test_msg("[   EXP  ] ${arg_exp}")
    if (DEFINED arg_msg)
      tkl_test_msg("[   MSG  ] ${arg_msg}")
    endif()
    tkl_set_global_prop(TACKLELIB_TESTLIB_TESTMODULE_RETCODE "tkl::testlib::testmodule::retcode" 1)

    tkl_testmodule_update_status()
  endif()

  unset(TACKLELIB_TESTLIB_TESTCASE_RETCODE)
  unset(TACKLELIB_TESTLIB_TESTMODULE_RETCODE)
endfunction()

# CAUTION:
#   Because the `tkl_test_assert*` only marks a test succeeded or failed, then you have to branch or exit
#   the test on your own to interrupt the testing.
#
macro(return_if_test_failed)
  if (${ARGC} GREATER 0)
    message(FATAL_ERROR "function must have no arguments")
  endif()

  tkl_get_global_prop(TACKLELIB_TESTLIB_TESTMODULE_INITED "tkl::testlib::testmodule::inited" 1)

  if (NOT TACKLELIB_TESTLIB_TESTMODULE_INITED)
    message(FATAL_ERROR "test module process is not initialized properly, call to `RunTestModule.cmake` to initialize and execute the test module process")
  endif()

  unset(TACKLELIB_TESTLIB_TESTMODULE_INITED)

  tkl_get_global_prop(TACKLELIB_TESTLIB_TESTMODULE_RETCODE "tkl::testlib::testmodule::retcode" 1)

  if (NOT TACKLELIB_TESTLIB_TESTMODULE_RETCODE)
    unset(TACKLELIB_TESTLIB_TESTMODULE_RETCODE)
    return()
  else()
    unset(TACKLELIB_TESTLIB_TESTMODULE_RETCODE)
  endif()
endmacro()

# Debug message with explicit enable/disable function.
# By default is disabled and must be enable in each test.
function(tkl_test_dbg_msg msg)
  tkl_get_global_prop(dbg_msg_enabled "tkl::testlib::testmodule::dbg_msg_enable" 1)
  if (dbg_msg_enabled)
    if (CMAKE_MAJOR_VERSION GREATER 3 OR CMAKE_MINOR_VERSION GREATER 14)
      message(DEBUG "[ DEBUG  ] ${msg}")
    else()
      message(STATUS "[ DEBUG  ] ${msg}")  # to print to stdout
    endif()
  endif()
endfunction()

function(tkl_enable_test_dbg_msg)
  set_property(GLOBAL PROPERTY "tkl::testlib::testmodule::dbg_msg_enable" 1)
endfunction()

function(tkl_disable_test_dbg_msg)
  set_property(GLOBAL PROPERTY "tkl::testlib::testmodule::dbg_msg_enable" 0)
endfunction()

endif()
