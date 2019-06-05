# inclusion guard for protection and speedup
if (NOT DEFINED TACKLELIB_TESTLIB_INCLUDE_DEFINED)
set(TACKLELIB_TESTLIB_INCLUDE_DEFINED 1)

include(tacklelib/Std)
include(tacklelib/ReturnCodeFile)
include(tacklelib/ForwardVariables)

if (NOT DEFINED TACKLELIB_TESTLIB_ROOT OR NOT IS_DIRECTORY "${TACKLELIB_TESTLIB_ROOT}")
  message(FATAL_ERROR "TACKLELIB_TESTLIB_ROOT variable must be defined externally before include this module: TACKLELIB_TESTLIB_ROOT=`${TACKLELIB_TESTLIB_ROOT}`")
endif()

function(tkl_testlib_init)
  # CAUTION:
  #   Must use global property here to avoid accidental misuse, because a variable existence would depend on a function context.
  #
  tkl_get_global_prop(TACKLELIB_TESTLIB_INITED "tkl::testlib::inited" 1)

  # single initialization
  if (TACKLELIB_TESTLIB_INITED)
    return()
  endif()

  tkl_make_var_from_CMAKE_ARGV_ARGC(-P argv)

  tkl_list_sublist(argv 1 -1 argv)
  #message("argv=${argv}")

  # parameterized flag argument values
  unset(path_match_filter_list)
  unset(test_case_match_filter_list)

  # parse flags until no flags
  tkl_parse_function_optional_flags_into_vars(
    .
    argv
    ""
    ""
    ""
    "\
path_match_filter\;.\;path_match_filter_list;\
test_case_match_filter\;.\;test_case_match_filter_list\
")

  # CAUTION:
  #   Must use global property here to avoid accidental misuse, because a variable existence would depend on a function context.
  #
  set_property(GLOBAL PROPERTY "tkl::testlib::path_match_filter" "${path_match_filter_list}")
  set_property(GLOBAL PROPERTY "tkl::testlib::test_case_match_filter" "${test_case_match_filter_list}")

  set(TACKLELIB_TESTLIB_CMAKE_ARGV "")
  set(cmake_arg_index 0)

  foreach(arg IN LISTS argv)
    # WORKAROUND: we have to replace because `foreach(... IN LISTS ...)` discardes ;-escaping
    string(REPLACE ";" "\;" arg "${arg}")

    list(APPEND TACKLELIB_TESTLIB_CMAKE_ARGV "${arg}")

    math(EXPR cmake_arg_index "${cmake_arg_index}+1")
  endforeach()

  set(TACKLELIB_TESTLIB_CMAKE_ARGC "${cmake_arg_index}")

  set_property(GLOBAL PROPERTY "tkl::testlib::cmake_argv" "${TACKLELIB_TESTLIB_CMAKE_ARGV}")
  set_property(GLOBAL PROPERTY "tkl::testlib::cmake_argc" "${TACKLELIB_TESTLIB_CMAKE_ARGC}")

  set_property(GLOBAL PROPERTY "tkl::testlib::working_dir" ".")

  set_property(GLOBAL PROPERTY "tkl::testlib::last_error" "-1")

  set_property(GLOBAL PROPERTY "tkl::testlib::last_enter_dir" "")

  set_property(GLOBAL PROPERTY "tkl::testlib::num_overall_tests" "0")
  set_property(GLOBAL PROPERTY "tkl::testlib::num_succeeded_tests" "0")
  set_property(GLOBAL PROPERTY "tkl::testlib::num_failed_tests" "0")

  set_property(GLOBAL PROPERTY "tkl::testlib::test_args" "")

  set_property(GLOBAL PROPERTY "tkl::testlib::testproc::index" "0")

  string(TIMESTAMP TACKLELIB_TESTLIB_START_TIME_SEC "%s" UTC)
  set_property(GLOBAL PROPERTY "tkl::testlib::start_time_sec" "${TACKLELIB_TESTLIB_START_TIME_SEC}")

  if (NOT DEFINED TESTS_ROOT OR NOT IS_DIRECTORY "${TESTS_ROOT}")
    message(FATAL_ERROR "TESTS_ROOT variable must be defained externally before include this module: TESTS_ROOT=`${TESTS_ROOT}`")
  endif()

  if (NOT DEFINED TACKLELIB_TESTLIB_TESTSCRIPT_FILE OR NOT EXISTS "${TACKLELIB_TESTLIB_TESTSCRIPT_FILE}" OR IS_DIRECTORY "${TACKLELIB_TESTLIB_TESTSCRIPT_FILE}")
    message(FATAL_ERROR "TACKLELIB_TESTLIB_TESTSCRIPT_FILE file path must exist before include this module: TACKLELIB_TESTLIB_TESTSCRIPT_FILE=`${TACKLELIB_TESTLIB_TESTSCRIPT_FILE}`")
  endif()

  # CAUTION:
  #   Must use global property here to avoid accidental misuse, because a variable existence would depend on a function context.
  #
  set_property(GLOBAL PROPERTY "tkl::testlib::inited" 1)
endfunction()

function(tkl_testlib_exit)
  tkl_get_global_prop(TACKLELIB_TESTLIB_INITED "tkl::testlib::inited" 1)

  if (NOT TACKLELIB_TESTLIB_INITED)
    message(FATAL_ERROR "Test library process is not initialized properly, call to `RunTestLib.cmake` to initialize and execute the test library process")
  endif()

  string(TIMESTAMP TACKLELIB_TESTLIB_END_TIME_SEC "%s" UTC)
  tkl_get_global_prop(TACKLELIB_TESTLIB_START_TIME_SEC "tkl::testlib::start_time_sec" 0)

  math(EXPR TACKLELIB_TESTLIB_RUN_TIME_SEC ${TACKLELIB_TESTLIB_END_TIME_SEC}-${TACKLELIB_TESTLIB_START_TIME_SEC})

  tkl_get_global_prop(TACKLELIB_TESTLIB_NUM_OVERALL_TESTS "tkl::testlib::num_overall_tests" 1)
  tkl_get_global_prop(TACKLELIB_TESTLIB_NUM_SUCCEEDED_TESTS "tkl::testlib::num_succeeded_tests" 1)
  tkl_get_global_prop(TACKLELIB_TESTLIB_NUM_FAILED_TESTS "tkl::testlib::num_failed_tests" 1)

  tkl_testlib_print_msg("RESULTS: failed/succeeded of overall: ${TACKLELIB_TESTLIB_NUM_FAILED_TESTS}/${TACKLELIB_TESTLIB_NUM_SUCCEEDED_TESTS} of ${TACKLELIB_TESTLIB_NUM_OVERALL_TESTS} (${TACKLELIB_TESTLIB_RUN_TIME_SEC}sec)\n===\n")
endfunction()

function(tkl_testlib_set_working_dir dir)
  set(TACKLELIB_TESTLIB_WORKING_DIR "${dir}")
  set_property(GLOBAL PROPERTY "tkl::testlib::working_dir" "${TACKLELIB_TESTLIB_WORKING_DIR}")
endfunction()

function(tkl_testlib_set_test_args)
  set(TACKLELIB_TESTLIB_TEST_ARGS "${ARGN}")
  set_property(GLOBAL PROPERTY "tkl::testlib::test_args" "${TACKLELIB_TESTLIB_TEST_ARGS}")
endfunction()

function(tkl_testlib_get_test_args out_var)
  tkl_get_global_prop(TACKLELIB_TESTLIB_TEST_ARGS "tkl::testlib::test_args" 1)
  set(${out_var} "${TACKLELIB_TESTLIB_TEST_ARGS}" PARENT_SCOPE)
endfunction()

function(tkl_testlib_print_msg msg)
  tkl_get_global_prop(TACKLELIB_TESTLIB_INITED "tkl::testlib::inited" 1)

  if (NOT TACKLELIB_TESTLIB_INITED)
    message(FATAL_ERROR "Test library process is not initialized properly, call to `RunTestLib.cmake` to initialize and execute the test library process")
  endif()

  tkl_get_global_prop(enter_dir_msg "tkl::testlib::stdout::enter_dir_msg" 0)
  if (DEFINED enter_dir_msg)
    message("${enter_dir_msg}")
    set_property(GLOBAL PROPERTY "tkl::testlib::stdout::enter_dir_msg") # unset property
  endif()

  message("${msg}")

  tkl_get_global_prop(num_print_msgs_in_dir "tkl::testlib::stdout::num_print_msgs_in_dir" 1)
  if (num_print_msgs_in_dir STREQUAL "")
    set(num_print_msgs_in_dir 0)
  endif()
  math(EXPR num_print_msgs_in_dir ${num_print_msgs_in_dir}+1)
  set_property(GLOBAL PROPERTY "tkl::testlib::num_print_msgs_in_dir" ${num_print_msgs_in_dir})
endfunction()

function(tkl_testlib_print_enter_dir_msg msg)
  tkl_get_global_prop(TACKLELIB_TESTLIB_INITED "tkl::testlib::inited" 1)

  if (NOT TACKLELIB_TESTLIB_INITED)
    message(FATAL_ERROR "Test library process is not initialized properly, call to `RunTestLib.cmake` to initialize and execute the test library process")
  endif()

  tkl_pushset_prop_to_stack(. GLOBAL "tkl::testlib::stdout::enter_dir_msg" "tkl::testlib" "${msg}")

  tkl_get_global_prop(num_print_msgs_in_dir "tkl::testlib::stdout::num_print_msgs_in_dir" 1)
  if (num_print_msgs_in_dir STREQUAL "")
    set(num_print_msgs_in_dir 0)
  endif()
  tkl_pushset_prop_to_stack(. GLOBAL "tkl::testlib::stdout::num_print_msgs_in_dir_stack" "tkl::testlib" ${num_print_msgs_in_dir})
  set_property(GLOBAL PROPERTY "tkl::testlib::stdout::num_print_msgs_in_dir" 0)

  tkl_get_global_prop(num_tests_run "tkl::testlib::num_tests_run" 1)
  if (num_tests_run STREQUAL "")
    set(num_tests_run 0)
  endif()
  tkl_pushset_prop_to_stack(. GLOBAL "tkl::testlib::num_tests_run_stack" "tkl::testlib" ${num_tests_run})
  set_property(GLOBAL PROPERTY "tkl::testlib::num_tests_run" 0)
endfunction()

function(tkl_testlib_print_leave_dir_msg msg)
  tkl_get_global_prop(TACKLELIB_TESTLIB_INITED "tkl::testlib::inited" 1)

  if (NOT TACKLELIB_TESTLIB_INITED)
    message(FATAL_ERROR "Test library process is not initialized properly, call to `RunTestLib.cmake` to initialize and execute the test library process")
  endif()

  tkl_pop_prop_from_stack(. GLOBAL "tkl::testlib::stdout::enter_dir_msg" "tkl::testlib")

  tkl_get_global_prop(num_print_msgs_in_dir "tkl::testlib::stdout::num_print_msgs_in_dir" 0)
  tkl_get_global_prop(num_tests_run "tkl::testlib::num_tests_run" 0)

  if (num_print_msgs_in_dir OR num_tests_run)
    message("${msg}")
  endif()

  tkl_pop_prop_from_stack(num_print_msgs_in_dir GLOBAL "tkl::testlib::stdout::num_print_msgs_in_dir_stack" "tkl::testlib")
  set_property(GLOBAL PROPERTY "tkl::testlib::stdout::num_print_msgs_in_dir" ${num_print_msgs_in_dir})

  tkl_pop_prop_from_stack(num_tests_run GLOBAL "tkl::testlib::num_tests_run_stack" "tkl::testlib")
  set_property(GLOBAL PROPERTY "tkl::testlib::num_tests_run" ${num_tests_run})
endfunction()

function(tkl_testlib_enter_dir test_dir)
  # Algorithm:
  #   1. Iterate not recursively over all `*.include.cmake` files and
  #      call to `tkl_testlib_include` function on each file, then
  #      if at least one is iterated then
  #      exit the algorithm.
  #   2. Iterate non recursively over all subdirectories and
  #      call to the algorithm recursively on each subdirectory, then
  #      continue.
  #   3. Iterate not recursively over all `*.test.cmake` files and
  #      call to `tkl_testlib_test` function on each file, then
  #      exit the algorithm.
  #

  tkl_get_global_prop(TACKLELIB_TESTLIB_INITED "tkl::testlib::inited" 1)

  if (NOT TACKLELIB_TESTLIB_INITED)
    message(FATAL_ERROR "Test library process is not initialized properly, call to `RunTestLib.cmake` to initialize and execute the test library process")
  endif()

  # CAUTION:
  #   Must use global property here to avoid accidental misuse, because a variable existence would depend on a function context.
  #
  tkl_get_global_prop(TACKLELIB_TESTLIB_PATH_MATCH_FILTER_LIST "tkl::testlib::path_match_filter" 1)
  tkl_get_global_prop(TACKLELIB_TESTLIB_TEST_CASE_MATCH_FILTER_LIST "tkl::testlib::test_case_match_filter" 1)

  tkl_get_global_prop(TACKLELIB_TESTLIB_LAST_ENTER_DIR "tkl::testlib::last_enter_dir" 1)

  if (TACKLELIB_TESTLIB_LAST_ENTER_DIR)
    if (NOT test_dir STREQUAL "" AND NOT test_dir STREQUAL ".")
      set(test_dir_path "${TACKLELIB_TESTLIB_LAST_ENTER_DIR}/${test_dir}")
    else()
      set(test_dir_path "${TACKLELIB_TESTLIB_LAST_ENTER_DIR}")
    endif()
  else()
    if (NOT test_dir STREQUAL "" AND NOT test_dir STREQUAL ".")
      set(test_dir_path "${test_dir}")
    else()
      set(test_dir_path ".")
    endif()
  endif()

  #message("tkl_testlib_enter_dir: ${test_dir_path}")

  # always set to special not zero value to provoke test to fail by default
  tkl_set_global_prop(TACKLELIB_TESTLIB_LAST_ERROR "tkl::testlib::last_error" -1)

  tkl_pushset_prop_to_stack(TACKLELIB_TESTLIB_LAST_ENTER_DIR GLOBAL "tkl::testlib::last_enter_dir" "tkl::testlib" "${test_dir_path}")

  tkl_pushset_prop_to_stack(TACKLELIB_TESTLIB_NUM_OVERALL_TESTS GLOBAL "tkl::testlib::num_overall_tests" "tkl::testlib" 0)
  tkl_pushset_prop_to_stack(TACKLELIB_TESTLIB_NUM_SUCCEEDED_TESTS GLOBAL "tkl::testlib::num_succeeded_tests" "tkl::testlib" 0)
  tkl_pushset_prop_to_stack(TACKLELIB_TESTLIB_NUM_FAILED_TESTS GLOBAL "tkl::testlib::num_failed_tests" "tkl::testlib" 0)

  tkl_testlib_print_enter_dir_msg("---\nEntering directory: `${TACKLELIB_TESTLIB_LAST_ENTER_DIR}`...")

  file(GLOB include_files
    LIST_DIRECTORIES false
    RELATIVE "${TESTS_ROOT}/${TACKLELIB_TESTLIB_LAST_ENTER_DIR}"
    "${TESTS_ROOT}/${TACKLELIB_TESTLIB_LAST_ENTER_DIR}/*.include.cmake"
  )

  if (include_files)
    foreach(include_file IN LISTS include_files)
      tkl_testlib_include("${TACKLELIB_TESTLIB_LAST_ENTER_DIR}" "${include_file}")
    endforeach()
  else()
    file(GLOB all_files
      #LIST_DIRECTORIES false
      RELATIVE "${TESTS_ROOT}/${TACKLELIB_TESTLIB_LAST_ENTER_DIR}"
      "${TESTS_ROOT}/${TACKLELIB_TESTLIB_LAST_ENTER_DIR}/*"
    )

    foreach(file_name IN LISTS all_files)
      if (NOT IS_DIRECTORY "${TESTS_ROOT}/${TACKLELIB_TESTLIB_LAST_ENTER_DIR}/${file_name}")
        continue()
      endif()

      tkl_testlib_enter_dir("${file_name}")
    endforeach()

    file(GLOB test_files
      LIST_DIRECTORIES false
      RELATIVE "${TESTS_ROOT}/${TACKLELIB_TESTLIB_LAST_ENTER_DIR}"
      "${TESTS_ROOT}/${TACKLELIB_TESTLIB_LAST_ENTER_DIR}/*.test.cmake"
    )

    if (TACKLELIB_TESTLIB_PATH_MATCH_FILTER_LIST STREQUAL "")
      foreach(test_file IN LISTS test_files)
        tkl_testlib_test("${TACKLELIB_TESTLIB_LAST_ENTER_DIR}" "${test_file}")
      endforeach()
    else()
      tkl_get_global_prop(TACKLELIB_FILE_SYSTEM_CASE_SENSITIVE "tkl::file_system::case_sensitive" 0)

      if (WIN32 OR (DEFINED TACKLELIB_FILE_SYSTEM_CASE_SENSITIVE AND NOT TACKLELIB_FILE_SYSTEM_CASE_SENSITIVE))
        foreach(test_file IN LISTS test_files)
          set(is_exclusively_included 0)
          set(is_excluded 0)

          string(TOLOWER "${TACKLELIB_TESTLIB_LAST_ENTER_DIR}/${test_file}" test_file_path_c)

          foreach(TACKLELIB_TESTLIB_PATH_MATCH_FILTER IN LISTS TACKLELIB_TESTLIB_PATH_MATCH_FILTER_LIST)
            tkl_regex_to_lower(regex_path_match_filter_c "${TACKLELIB_TESTLIB_PATH_MATCH_FILTER}")

            set(is_include_filter 1)
            if (NOT regex_path_match_filter_c STREQUAL "")
              string(SUBSTRING "${regex_path_match_filter_c}" 0 1 regex_path_match_filter_prefix_char)
              if (regex_path_match_filter_prefix_char STREQUAL "-")
                string(SUBSTRING "${regex_path_match_filter_c}" 1 -1 regex_path_match_filter_c)
                set(is_include_filter 0)
              elseif (regex_path_match_filter_prefix_char STREQUAL "+")
                string(SUBSTRING "${regex_path_match_filter_c}" 1 -1 regex_path_match_filter_c)
              endif()
            endif()

            if (NOT is_exclusively_included AND is_include_filter AND "${test_file_path_c}" MATCHES "${regex_path_match_filter_c}")
              set(is_exclusively_included 1)
            endif()

            if (NOT is_include_filter AND "${test_file_path_c}" MATCHES "${regex_path_match_filter_c}")
              set(is_excluded 1)
              break()
            endif()
          endforeach()

          if (is_exclusively_included AND (NOT is_excluded))
            tkl_testlib_test("${TACKLELIB_TESTLIB_LAST_ENTER_DIR}" "${test_file}")
          endif()
        endforeach()
      else()
        foreach(test_file IN LISTS test_files)
          set(is_exclusively_included 0)
          set(is_excluded 0)

          foreach(TACKLELIB_TESTLIB_PATH_MATCH_FILTER IN LISTS TACKLELIB_TESTLIB_PATH_MATCH_FILTER_LIST)
            set(regex_path_match_filter_c "${TACKLELIB_TESTLIB_PATH_MATCH_FILTER}")

            set(is_include_filter 1)
            if (NOT regex_path_match_filter_c STREQUAL "")
              string(SUBSTRING "${regex_path_match_filter_c}" 0 1 regex_path_match_filter_prefix_char)
              if (regex_path_match_filter_prefix_char STREQUAL "-")
                string(SUBSTRING "${regex_path_match_filter_c}" 1 -1 regex_path_match_filter_c)
                set(is_include_filter 0)
              elseif (regex_path_match_filter_prefix_char STREQUAL "+")
                string(SUBSTRING "${regex_path_match_filter_c}" 1 -1 regex_path_match_filter_c)
              endif()
            endif()

            if (NOT is_exclusively_included AND is_include_filter AND "${TACKLELIB_TESTLIB_LAST_ENTER_DIR}/${test_file}" MATCHES "${regex_path_match_filter_c}")
              set(is_exclusively_included 1)
            endif()

            if (NOT is_include_filter AND "${TACKLELIB_TESTLIB_LAST_ENTER_DIR}/${test_file}" MATCHES "${regex_path_match_filter_c}")
              set(is_excluded 1)
              break()
            endif()
          endforeach()

          if (is_exclusively_included AND (NOT is_excluded))
            tkl_testlib_test("${TACKLELIB_TESTLIB_LAST_ENTER_DIR}" "${test_file}")
          endif()
        endforeach()
      endif()
    endif()
  endif()

  # reread testlib states
  tkl_get_global_prop(TACKLELIB_TESTLIB_NUM_OVERALL_TESTS_CHILDREN "tkl::testlib::num_overall_tests" 1)
  tkl_get_global_prop(TACKLELIB_TESTLIB_NUM_SUCCEEDED_TESTS_CHILDREN "tkl::testlib::num_succeeded_tests" 1)
  tkl_get_global_prop(TACKLELIB_TESTLIB_NUM_FAILED_TESTS_CHILDREN "tkl::testlib::num_failed_tests" 1)

  tkl_pop_prop_from_stack(TACKLELIB_TESTLIB_NUM_OVERALL_TESTS GLOBAL "tkl::testlib::num_overall_tests" "tkl::testlib")
  tkl_pop_prop_from_stack(TACKLELIB_TESTLIB_NUM_SUCCEEDED_TESTS GLOBAL "tkl::testlib::num_succeeded_tests" "tkl::testlib")
  tkl_pop_prop_from_stack(TACKLELIB_TESTLIB_NUM_FAILED_TESTS GLOBAL "tkl::testlib::num_failed_tests" "tkl::testlib")

  # increment states
  math(EXPR TACKLELIB_TESTLIB_NUM_OVERALL_TESTS "${TACKLELIB_TESTLIB_NUM_OVERALL_TESTS}+${TACKLELIB_TESTLIB_NUM_OVERALL_TESTS_CHILDREN}")
  math(EXPR TACKLELIB_TESTLIB_NUM_SUCCEEDED_TESTS "${TACKLELIB_TESTLIB_NUM_SUCCEEDED_TESTS}+${TACKLELIB_TESTLIB_NUM_SUCCEEDED_TESTS_CHILDREN}")
  math(EXPR TACKLELIB_TESTLIB_NUM_FAILED_TESTS "${TACKLELIB_TESTLIB_NUM_FAILED_TESTS}+${TACKLELIB_TESTLIB_NUM_FAILED_TESTS_CHILDREN}")

  # write testlib states
  set_property(GLOBAL PROPERTY "tkl::testlib::num_overall_tests" "${TACKLELIB_TESTLIB_NUM_OVERALL_TESTS}")
  set_property(GLOBAL PROPERTY "tkl::testlib::num_succeeded_tests" "${TACKLELIB_TESTLIB_NUM_SUCCEEDED_TESTS}")
  set_property(GLOBAL PROPERTY "tkl::testlib::num_failed_tests" "${TACKLELIB_TESTLIB_NUM_FAILED_TESTS}")

  if (TACKLELIB_TESTLIB_NUM_OVERALL_TESTS_CHILDREN)
    tkl_testlib_print_leave_dir_msg("Leaving directory: `${TACKLELIB_TESTLIB_LAST_ENTER_DIR}`: failed/succeeded of overall: ${TACKLELIB_TESTLIB_NUM_FAILED_TESTS_CHILDREN}/${TACKLELIB_TESTLIB_NUM_SUCCEEDED_TESTS_CHILDREN} of ${TACKLELIB_TESTLIB_NUM_OVERALL_TESTS_CHILDREN}\n---\n")
  else()
    # tests are not found or filtered out
    tkl_testlib_print_leave_dir_msg("Leaving directory: `${TACKLELIB_TESTLIB_LAST_ENTER_DIR}`\n---\n")
  endif()

  tkl_pop_prop_from_stack(. GLOBAL "tkl::testlib::last_enter_dir" "tkl::testlib")
endfunction()

macro(tkl_testlib_include test_dir test_file_name)
  tkl_get_global_prop(TACKLELIB_TESTLIB_INITED "tkl::testlib::inited" 1)

  if (NOT TACKLELIB_TESTLIB_INITED)
    message(FATAL_ERROR "Test library process is not initialized properly, call to `RunTestLib.cmake` to initialize and execute the test library process")
  endif()

  tkl_get_global_prop(TACKLELIB_TESTLIB_LAST_ENTER_DIR "tkl::testlib::last_enter_dir" 1)

  tkl_get_global_prop(TACKLELIB_TESTLIB_PATH_MATCH_FILTER_LIST "tkl::testlib::path_match_filter" 1)
  tkl_get_global_prop(TACKLELIB_TESTLIB_TEST_CASE_MATCH_FILTER_LIST "tkl::testlib::test_case_match_filter" 1)

  if (NOT test_dir STREQUAL "" AND NOT test_dir STREQUAL ".")
    if (EXISTS "${TESTS_ROOT}/${test_dir}/${test_file_name}" AND
        NOT IS_DIRECTORY "${TESTS_ROOT}/${test_dir}/${test_file_name}")
      include("${TESTS_ROOT}/${test_dir}/${test_file_name}")
    elseif (EXISTS "${TESTS_ROOT}/${test_dir}/${test_file_name}.cmake" AND
        NOT IS_DIRECTORY "${TESTS_ROOT}/${test_dir}/${test_file_name}.cmake")
      include("${TESTS_ROOT}/${test_dir}/${test_file_name}.cmake")
    else()
      message(FATAL_ERROR "failed to include file: `${TESTS_ROOT}/${test_dir}/${test_file_name}`")
    endif()
  else()
    if (EXISTS "${TESTS_ROOT}/${test_file_name}" AND
        NOT IS_DIRECTORY "${TESTS_ROOT}/${test_file_name}")
      include("${TESTS_ROOT}/${test_file_name}")
    elseif (EXISTS "${TESTS_ROOT}/${test_file_name}.cmake" AND
        NOT IS_DIRECTORY "${TESTS_ROOT}/${test_file_name}.cmake")
      include("${TESTS_ROOT}/${test_file_name}.cmake")
    else()
      message(FATAL_ERROR "failed to include file: `${TESTS_ROOT}/${test_file_name}`")
    endif()
  endif()
endmacro()

function(tkl_testlib_test_file_shortcut test_file_path out_var)
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

function(tkl_testlib_test test_dir test_file_name)
  tkl_get_global_prop(TACKLELIB_TESTLIB_INITED "tkl::testlib::inited" 1)

  if (NOT TACKLELIB_TESTLIB_INITED)
    message(FATAL_ERROR "Test library process is not initialized properly, call to `RunTestLib.cmake` to initialize and execute the test library process")
  endif()

  set(ret_code 0)

  if (NOT test_dir STREQUAL "" AND NOT test_dir STREQUAL ".")
    set(test_file_dir "${TESTS_ROOT}/${test_dir}")
    set(test_file_dir_prefix "${test_dir}/")
  else()
    set(test_file_dir "${TESTS_ROOT}")
    set(test_file_dir_prefix "")
  endif()

  set(test_file_name_ext "${test_file_name}")
  if (NOT test_file_name_ext MATCHES ".*\.cmake" AND
      NOT EXISTS "${test_file_dir}/${test_file_name_ext}" AND
      EXISTS "${test_file_dir}/${test_file_name_ext}.cmake")
    set(test_file_name_ext "${test_file_name}.cmake")
  endif()

  set(test_file_path "${test_file_dir}/${test_file_name_ext}")

  #message("tkl_testlib_test: ${test_file_path}")

  tkl_get_global_prop(num_tests_run "tkl::testlib::num_tests_run" 1)
  if (num_tests_run STREQUAL "")
    set(num_tests_run 0)
  endif()
  math(EXPR num_tests_run ${num_tests_run}+1)
  set_property(GLOBAL PROPERTY "tkl::testlib::num_tests_run" ${num_tests_run})

  tkl_testlib_test_file_shortcut("${test_file_dir_prefix}${test_file_name_ext}" TACKLELIB_TESTLIB_FILE_REL_PATH_SHORTCUT)

  tkl_testlib_print_msg("[RUNNING ] `${TACKLELIB_TESTLIB_FILE_REL_PATH_SHORTCUT}`...")

  tkl_make_ret_code_file_dir(ret_code_dir)

  tkl_get_global_prop(TACKLELIB_TESTLIB_TESTPROC_INDEX "tkl::testlib::testproc::index" 1)

  tkl_get_global_prop(TACKLELIB_TESTLIB_NUM_OVERALL_TESTS "tkl::testlib::num_overall_tests" 1)
  tkl_get_global_prop(TACKLELIB_TESTLIB_NUM_SUCCEEDED_TESTS "tkl::testlib::num_succeeded_tests" 1)
  tkl_get_global_prop(TACKLELIB_TESTLIB_NUM_FAILED_TESTS "tkl::testlib::num_failed_tests" 1)

  tkl_testlib_get_test_args(TACKLELIB_TESTLIB_TEST_ARGS)

  tkl_get_global_prop(TACKLELIB_TESTLIB_TEST_CASE_MATCH_FILTER_LIST "tkl::testlib::test_case_match_filter" 1)

  string(TIMESTAMP TACKLELIB_TESTLIB_START_TIME_SEC "%s" UTC)

  if (DEFINED TACKLELIB_TESTLIB_WORKING_DIR AND NOT TACKLELIB_TESTLIB_WORKING_DIR STREQUAL "" AND NOT TACKLELIB_TESTLIB_WORKING_DIR STREQUAL ".")
    execute_process(
      COMMAND
        "${CMAKE_COMMAND}"
        "-DCMAKE_MODULE_PATH=${CMAKE_MODULE_PATH}"
        "-DPROJECT_ROOT=${PROJECT_ROOT}"
        "-DTESTS_ROOT=${TESTS_ROOT}"
        "-DTACKLELIB_TESTLIB_TESTPROC_RETCODE_DIR=${ret_code_dir}"
        "-DTACKLELIB_TESTLIB_TESTPROC_INDEX=${TACKLELIB_TESTLIB_TESTPROC_INDEX}"
        "-DTACKLELIB_TESTLIB_TESTMODULE_FILE=${test_file_path}"
        "-DTACKLELIB_TESTLIB_TEST_CASE_MATCH_FILTER_LIST=${TACKLELIB_TESTLIB_TEST_CASE_MATCH_FILTER_LIST}"
        -P
        "${TACKLELIB_TESTLIB_ROOT}/tools/RunTestModule.cmake"
      WORKING_DIRECTORY
        "${TACKLELIB_TESTLIB_WORKING_DIR}"
      RESULT_VARIABLE
        TACKLELIB_TESTLIB_LAST_ERROR
    )
  else()
    execute_process(
      COMMAND
        "${CMAKE_COMMAND}"
        "-DCMAKE_MODULE_PATH=${CMAKE_MODULE_PATH}"
        "-DPROJECT_ROOT=${PROJECT_ROOT}"
        "-DTESTS_ROOT=${TESTS_ROOT}"
        "-DTACKLELIB_TESTLIB_TESTPROC_RETCODE_DIR=${ret_code_dir}"
        "-DTACKLELIB_TESTLIB_TESTPROC_INDEX=${TACKLELIB_TESTLIB_TESTPROC_INDEX}"
        "-DTACKLELIB_TESTLIB_TESTMODULE_FILE=${test_file_path}"
        "-DTACKLELIB_TESTLIB_TEST_CASE_MATCH_FILTER_LIST=${TACKLELIB_TESTLIB_TEST_CASE_MATCH_FILTER_LIST}"
        -P
        "${TACKLELIB_TESTLIB_ROOT}/tools/RunTestModule.cmake"
      RESULT_VARIABLE
        TACKLELIB_TESTLIB_LAST_ERROR
    )
  endif()

  string(TIMESTAMP TACKLELIB_TESTLIB_END_TIME_SEC "%s" UTC)

  math(EXPR TACKLELIB_TESTLIB_RUN_TIME_SEC ${TACKLELIB_TESTLIB_END_TIME_SEC}-${TACKLELIB_TESTLIB_START_TIME_SEC})

  set_property(GLOBAL PROPERTY "tkl::testlib::last_error" "${TACKLELIB_TESTLIB_LAST_ERROR}")

  if (NOT TACKLELIB_TESTLIB_LAST_ERROR)
    tkl_get_ret_code_from_file_dir("${ret_code_dir}" TACKLELIB_TESTLIB_LAST_ERROR)
  endif()

  tkl_remove_ret_code_file_dir("${ret_code_dir}")

  math(EXPR TACKLELIB_TESTLIB_NUM_OVERALL_TESTS "${TACKLELIB_TESTLIB_NUM_OVERALL_TESTS}+1")

  if (TACKLELIB_TESTLIB_LAST_ERROR EQUAL 0)
    math(EXPR TACKLELIB_TESTLIB_NUM_SUCCEEDED_TESTS "${TACKLELIB_TESTLIB_NUM_SUCCEEDED_TESTS}+1")
    tkl_testlib_print_msg("[   OK   ] `${TACKLELIB_TESTLIB_FILE_REL_PATH_SHORTCUT}` (${TACKLELIB_TESTLIB_RUN_TIME_SEC}sec)")
  else()
    math(EXPR TACKLELIB_TESTLIB_NUM_FAILED_TESTS "${TACKLELIB_TESTLIB_NUM_FAILED_TESTS}+1")
    tkl_testlib_print_msg("[ FAILED ] `${TACKLELIB_TESTLIB_FILE_REL_PATH_SHORTCUT}` (${TACKLELIB_TESTLIB_RUN_TIME_SEC}sec)")
  endif()

  set_property(GLOBAL PROPERTY "tkl::testlib::num_overall_tests" "${TACKLELIB_TESTLIB_NUM_OVERALL_TESTS}")
  set_property(GLOBAL PROPERTY "tkl::testlib::num_succeeded_tests" "${TACKLELIB_TESTLIB_NUM_SUCCEEDED_TESTS}")
  set_property(GLOBAL PROPERTY "tkl::testlib::num_failed_tests" "${TACKLELIB_TESTLIB_NUM_FAILED_TESTS}")

  math(EXPR TACKLELIB_TESTLIB_TESTPROC_INDEX "${TACKLELIB_TESTLIB_TESTPROC_INDEX}+1")

  set_property(GLOBAL PROPERTY "tkl::testlib::testproc::index" "${TACKLELIB_TESTLIB_TESTPROC_INDEX}")
endfunction()

endif()
