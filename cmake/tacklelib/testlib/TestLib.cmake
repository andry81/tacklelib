# inclusion guard for protection and speedup
if (NOT DEFINED TACKLELIB_TESTLIB_INCLUDE_DEFINED)
set(TACKLELIB_TESTLIB_INCLUDE_DEFINED 1)

include(tacklelib/Std)
include(tacklelib/ReturnCodeFile)
include(tacklelib/ForwardVariables)

function(tkl_testlib_init)
  # CAUTION:
  #   Must use global property here to avoid accidental misuse, because a variable existence would depend on a function context.
  #
  tkl_get_global_prop(TACKLELIB_TESTLIB_INITED "tkl::testlib::inited" 1)

  if (TACKLELIB_TESTLIB_INITED)
    return()
  endif()

  tkl_make_var_from_CMAKE_ARGV_ARGC(-P argv)

  tkl_list_sublist(argv 1 -1 argv)
  #message("argv=${argv}")

  # parameterized flag argument values
  unset(path_match_filter_list)

  # parse flags until no flags
  tkl_parse_function_optional_flags_into_vars(
    .
    argv
    ""
    ""
    ""
    "path_match_filter\;.\;path_match_filter_list")

  # CAUTION:
  #   Must use global property here to avoid accidental misuse, because a variable existence would depend on a function context.
  #
  set_property(GLOBAL PROPERTY "tkl::testlib::path_match_filter" "${path_match_filter_list}")

  set(TACKLELIB_TESTLIB_CMAKE_ARGV "")

  set(cmake_arg_index 0)
  set(cmake_arg_prev_index 0)

  # arguments excluding first one
  while(cmake_arg_index LESS CMAKE_ARGC)
    if (cmake_arg_index GREATER 0)
      list(APPEND TACKLELIB_TESTLIB_CMAKE_ARGV "${CMAKE_ARGV${cmake_arg_index}}")
    endif()

    set(cmake_arg_prev_index ${cmake_arg_index})
    math(EXPR cmake_arg_index "${cmake_arg_index}+1")
  endwhile()
 
  set(TACKLELIB_TESTLIB_CMAKE_ARGC "${cmake_arg_prev_index}")

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

  if (NOT DEFINED TESTS_ROOT)
    message(FATAL_ERROR "TESTS_ROOT must be defined")
  endif()

  if (NOT DEFINED TEST_SCRIPT_FILE_NAME)
    message(FATAL_ERROR "TEST_SCRIPT_FILE_NAME must be defined")
  endif()

  # CAUTION:
  #   Must use global property here to avoid accidental misuse, because a variable existence would depend on a function context.
  #
  set_property(GLOBAL PROPERTY "tkl::testlib::inited" 1)
endfunction()

macro(tkl_testlib_set_working_dir dir)
  set(TACKLELIB_TESTLIB_WORKING_DIR "${dir}")
  set_property(GLOBAL PROPERTY "tkl::testlib::working_dir" "${TACKLELIB_TESTLIB_WORKING_DIR}")
endmacro()

macro(tkl_testlib_set_test_args)
  set(TACKLELIB_TESTLIB_TEST_ARGS "${ARGN}")
  set_property(GLOBAL PROPERTY "tkl::testlib::test_args" "${TACKLELIB_TESTLIB_TEST_ARGS}")
endmacro()

function(tkl_testlib_print_msg msg)
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
  tkl_pushset_prop_to_stack(. GLOBAL "tkl::testlib::stdout::enter_dir_msg" "${msg}")

  tkl_get_global_prop(num_print_msgs_in_dir "tkl::testlib::stdout::num_print_msgs_in_dir" 1)
  if (num_print_msgs_in_dir STREQUAL "")
    set(num_print_msgs_in_dir 0)
  endif()
  tkl_pushset_prop_to_stack(. GLOBAL "tkl::testlib::stdout::num_print_msgs_in_dir_stack" ${num_print_msgs_in_dir})
  set_property(GLOBAL PROPERTY "tkl::testlib::stdout::num_print_msgs_in_dir" 0)

  tkl_get_global_prop(num_tests_run "tkl::testlib::num_tests_run" 1)
  if (num_tests_run STREQUAL "")
    set(num_tests_run 0)
  endif()
  tkl_pushset_prop_to_stack(. GLOBAL "tkl::testlib::num_tests_run_stack" ${num_tests_run})
  set_property(GLOBAL PROPERTY "tkl::testlib::num_tests_run" 0)
endfunction()

function(tkl_testlib_print_leave_dir_msg msg)
  tkl_pop_prop_from_stack(. GLOBAL "tkl::testlib::stdout::enter_dir_msg")

  tkl_get_global_prop(num_print_msgs_in_dir "tkl::testlib::stdout::num_print_msgs_in_dir" 0)
  tkl_get_global_prop(num_tests_run "tkl::testlib::num_tests_run" 0)

  if (num_print_msgs_in_dir OR num_tests_run)
    message("${msg}")
  endif()

  tkl_pop_prop_from_stack(num_print_msgs_in_dir GLOBAL "tkl::testlib::stdout::num_print_msgs_in_dir_stack")
  set_property(GLOBAL PROPERTY "tkl::testlib::stdout::num_print_msgs_in_dir" ${num_print_msgs_in_dir})

  tkl_pop_prop_from_stack(num_tests_run GLOBAL "tkl::testlib::num_tests_run_stack")
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

  # CAUTION:
  #   Must use global property here to avoid accidental misuse, because a variable existence would depend on a function context.
  #
  tkl_get_global_prop(TACKLELIB_TESTLIB_PATH_MATCH_FILTER_LIST "tkl::testlib::path_match_filter" 1)
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

  # always set to special not zero value to provoke test to fail by default
  tkl_set_global_prop_and_var(TACKLELIB_TESTLIB_LAST_ERROR "tkl::testlib::last_error" -1)

  tkl_pushset_prop_to_stack(TACKLELIB_TESTLIB_LAST_ENTER_DIR GLOBAL "tkl::testlib::last_enter_dir" "${test_dir_path}")

  tkl_pushset_prop_to_stack(TACKLELIB_TESTLIB_NUM_OVERALL_TESTS GLOBAL "tkl::testlib::num_overall_tests" 0)
  tkl_pushset_prop_to_stack(TACKLELIB_TESTLIB_NUM_SUCCEEDED_TESTS GLOBAL "tkl::testlib::num_succeeded_tests" 0)
  tkl_pushset_prop_to_stack(TACKLELIB_TESTLIB_NUM_FAILED_TESTS GLOBAL "tkl::testlib::num_failed_tests" 0)

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

    file(GLOB aaa
      LIST_DIRECTORIES false
      #RELATIVE "${TESTS_ROOT}/${TACKLELIB_TESTLIB_LAST_ENTER_DIR}"
      "${TESTS_ROOT}/${TACKLELIB_TESTLIB_LAST_ENTER_DIR}/*.test.cmake"
    )

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
      tkl_get_global_prop(TACKLELIB_FILE_SYSTEM_CASE_SENSITIVE GLOBAL PROPERTY "tkl::file_system::case_sensitive" 0)

      if (WIN32 OR (DEFINED TACKLELIB_FILE_SYSTEM_CASE_SENSITIVE AND NOT TACKLELIB_FILE_SYSTEM_CASE_SENSITIVE))
        foreach(test_file IN LISTS test_files)
          foreach(TACKLELIB_TESTLIB_PATH_MATCH_FILTER IN LISTS TACKLELIB_TESTLIB_PATH_MATCH_FILTER_LIST)
            string(TOLOWER "${TACKLELIB_TESTLIB_LAST_ENTER_DIR}/${test_file}" test_file_path_c)
            tkl_regex_to_lower("${TACKLELIB_TESTLIB_PATH_MATCH_FILTER}" regex_path_match_filter_c)
            if ("${test_file_path_c}" MATCHES "${regex_path_match_filter_c}")
              tkl_testlib_test("${TACKLELIB_TESTLIB_LAST_ENTER_DIR}" "${test_file}")
              break()
            endif()
          endforeach()
        endforeach()
      else()
        foreach(test_file IN LISTS test_files)
          foreach(TACKLELIB_TESTLIB_PATH_MATCH_FILTER IN LISTS TACKLELIB_TESTLIB_PATH_MATCH_FILTER_LIST)
            if ("${TACKLELIB_TESTLIB_LAST_ENTER_DIR}/${test_file}" MATCHES "${TACKLELIB_TESTLIB_PATH_MATCH_FILTER}")
              tkl_testlib_test("${TACKLELIB_TESTLIB_LAST_ENTER_DIR}" "${test_file}")
              break()
            endif()
          endforeach()
        endforeach()
      endif()
    endif()
  endif()

  # reread testlib states
  tkl_get_global_prop(TACKLELIB_TESTLIB_NUM_OVERALL_TESTS_CHILDREN "tkl::testlib::num_overall_tests" 1)
  tkl_get_global_prop(TACKLELIB_TESTLIB_NUM_SUCCEEDED_TESTS_CHILDREN "tkl::testlib::num_succeeded_tests" 1)
  tkl_get_global_prop(TACKLELIB_TESTLIB_NUM_FAILED_TESTS_CHILDREN "tkl::testlib::num_failed_tests" 1)

  tkl_pop_prop_from_stack(TACKLELIB_TESTLIB_NUM_OVERALL_TESTS GLOBAL "tkl::testlib::num_overall_tests")
  tkl_pop_prop_from_stack(TACKLELIB_TESTLIB_NUM_SUCCEEDED_TESTS GLOBAL "tkl::testlib::num_succeeded_tests")
  tkl_pop_prop_from_stack(TACKLELIB_TESTLIB_NUM_FAILED_TESTS GLOBAL "tkl::testlib::num_failed_tests")

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

  tkl_pop_prop_from_stack(. GLOBAL "tkl::testlib::last_enter_dir")
  tkl_get_global_prop(TACKLELIB_TESTLIB_LAST_ENTER_DIR "tkl::testlib::last_enter_dir" 1)
endfunction()

macro(tkl_testlib_exit)
  tkl_get_global_prop(TACKLELIB_TESTLIB_NUM_OVERALL_TESTS "tkl::testlib::num_overall_tests" 1)
  tkl_get_global_prop(TACKLELIB_TESTLIB_NUM_SUCCEEDED_TESTS "tkl::testlib::num_succeeded_tests" 1)
  tkl_get_global_prop(TACKLELIB_TESTLIB_NUM_FAILED_TESTS "tkl::testlib::num_failed_tests" 1)

  tkl_testlib_print_msg("RESULTS: failed/succeeded of overall: ${TACKLELIB_TESTLIB_NUM_FAILED_TESTS}/${TACKLELIB_TESTLIB_NUM_SUCCEEDED_TESTS} of ${TACKLELIB_TESTLIB_NUM_OVERALL_TESTS}\n===\n")
endmacro()

macro(tkl_testlib_include test_dir test_file_name)
  tkl_get_global_prop(TACKLELIB_TESTLIB_LAST_ENTER_DIR "tkl::testlib::last_enter_dir" 1)
  tkl_get_global_prop(TACKLELIB_TESTLIB_PATH_MATCH_FILTER_LIST "tkl::testlib::path_match_filter" 1)

  if (NOT test_dir STREQUAL "" AND NOT test_dir STREQUAL .)
    if (EXISTS "${TESTS_ROOT}/${test_dir}/${test_file_name}" AND
        NOT IS_DIRECTORY "${TESTS_ROOT}/${test_dir}/${test_file_name}")
      if (TACKLELIB_TESTLIB_PATH_MATCH_FILTER_LIST STREQUAL "")
        include("${TESTS_ROOT}/${test_dir}/${test_file_name}")
      else()
        tkl_get_global_prop(TACKLELIB_FILE_SYSTEM_CASE_SENSITIVE GLOBAL PROPERTY "tkl::file_system::case_sensitive" 0)

        if (WIN32 OR (DEFINED TACKLELIB_FILE_SYSTEM_CASE_SENSITIVE AND NOT TACKLELIB_FILE_SYSTEM_CASE_SENSITIVE))
          foreach(TACKLELIB_TESTLIB_PATH_MATCH_FILTER IN LISTS TACKLELIB_TESTLIB_PATH_MATCH_FILTER_LIST)
            string(TOLOWER "${TESTS_ROOT}/${test_dir}/${test_file_name}" _D089F11A_test_file_path_c)
            tkl_regex_to_lower("${TACKLELIB_TESTLIB_PATH_MATCH_FILTER}" _D089F11A_regex_path_match_filter_c)
            if ("${_D089F11A_test_file_path_c}" MATCHES "${_D089F11A_regex_path_match_filter_c}")
              unset(_D089F11A_test_file_path_c)
              unset(_D089F11A_regex_path_match_filter_c)
              include("${TESTS_ROOT}/${test_dir}/${test_file_name}")
              break()
            endif()
          endforeach()
        else()
          foreach(TACKLELIB_TESTLIB_PATH_MATCH_FILTER IN LISTS TACKLELIB_TESTLIB_PATH_MATCH_FILTER_LIST)
            if ("${TESTS_ROOT}/${test_dir}/${test_file_name}" MATCHES "${TACKLELIB_TESTLIB_PATH_MATCH_FILTER}")
              include("${TESTS_ROOT}/${test_dir}/${test_file_name}")
              break()
            endif()
          endforeach()
        endif()
      endif()
    elseif (EXISTS "${TESTS_ROOT}/${test_dir}/${test_file_name}.cmake" AND
        NOT IS_DIRECTORY "${TESTS_ROOT}/${test_dir}/${test_file_name}.cmake")
      if (TACKLELIB_TESTLIB_PATH_MATCH_FILTER_LIST STREQUAL "")
        include("${TESTS_ROOT}/${test_dir}/${test_file_name}.cmake")
      else()
        tkl_get_global_prop(TACKLELIB_FILE_SYSTEM_CASE_SENSITIVE GLOBAL PROPERTY "tkl::file_system::case_sensitive" 0)

        if (WIN32 OR (DEFINED TACKLELIB_FILE_SYSTEM_CASE_SENSITIVE AND NOT TACKLELIB_FILE_SYSTEM_CASE_SENSITIVE))
          foreach(TACKLELIB_TESTLIB_PATH_MATCH_FILTER IN LISTS TACKLELIB_TESTLIB_PATH_MATCH_FILTER_LIST)
            string(TOLOWER "${TESTS_ROOT}/${test_dir}/${test_file_name}.cmake" _D089F11A_test_file_path_c)
            tkl_regex_to_lower("${TACKLELIB_TESTLIB_PATH_MATCH_FILTER}" _D089F11A_regex_path_match_filter_c)
            if ("${_D089F11A_test_file_path_c}" MATCHES "${_D089F11A_regex_path_match_filter_c}")
              unset(_D089F11A_test_file_path_c)
              unset(_D089F11A_regex_path_match_filter_c)
              include("${TESTS_ROOT}/${test_dir}/${test_file_name}.cmake")
              break()
            endif()
          endforeach()
        else()
          foreach(TACKLELIB_TESTLIB_PATH_MATCH_FILTER IN LISTS TACKLELIB_TESTLIB_PATH_MATCH_FILTER_LIST)
            if ("${TESTS_ROOT}/${test_dir}/${test_file_name}.cmake" MATCHES "${TACKLELIB_TESTLIB_PATH_MATCH_FILTER}")
              include("${TESTS_ROOT}/${test_dir}/${test_file_name}.cmake")
              break()
            endif()
          endforeach()
        endif()
      endif()
    else()
      message(FATAL_ERROR "failed to include file: `${TESTS_ROOT}/${test_dir}/${test_file_name}`")
    endif()
  else()
    if (EXISTS "${TESTS_ROOT}/${test_file_name}" AND
        NOT IS_DIRECTORY "${TESTS_ROOT}/${test_file_name}")
      if (TACKLELIB_TESTLIB_PATH_MATCH_FILTER_LIST STREQUAL "")
        include("${TESTS_ROOT}/${test_file_name}")
      else()
        tkl_get_global_prop(TACKLELIB_FILE_SYSTEM_CASE_SENSITIVE GLOBAL PROPERTY "tkl::file_system::case_sensitive" 0)

        if (WIN32 OR (DEFINED TACKLELIB_FILE_SYSTEM_CASE_SENSITIVE AND NOT TACKLELIB_FILE_SYSTEM_CASE_SENSITIVE))
          foreach(TACKLELIB_TESTLIB_PATH_MATCH_FILTER IN LISTS TACKLELIB_TESTLIB_PATH_MATCH_FILTER_LIST)
            string(TOLOWER "${TESTS_ROOT}/${test_file_name}" _D089F11A_test_file_path_c)
            tkl_regex_to_lower("${TACKLELIB_TESTLIB_PATH_MATCH_FILTER}" _D089F11A_regex_path_match_filter_c)
            if ("${_D089F11A_test_file_path_c}" MATCHES "${_D089F11A_regex_path_match_filter_c}")
              unset(_D089F11A_test_file_path_c)
              unset(_D089F11A_regex_path_match_filter_c)
              include("${TESTS_ROOT}/${test_file_name}")
              break()
            endif()
          endforeach()
        else()
          foreach(TACKLELIB_TESTLIB_PATH_MATCH_FILTER IN LISTS TACKLELIB_TESTLIB_PATH_MATCH_FILTER_LIST)
            if ("${TESTS_ROOT}/${test_file_name}" MATCHES "${TACKLELIB_TESTLIB_PATH_MATCH_FILTER}")
              include("${TESTS_ROOT}/${test_file_name}")
              break()
            endif()
          endforeach()
        endif()
      endif()
    elseif (EXISTS "${TESTS_ROOT}/${test_file_name}.cmake" AND
        NOT IS_DIRECTORY "${TESTS_ROOT}/${test_file_name}.cmake")
      if (TACKLELIB_TESTLIB_PATH_MATCH_FILTER_LIST STREQUAL "")
        include("${TESTS_ROOT}/${test_file_name}.cmake")
      else()
        tkl_get_global_prop(TACKLELIB_FILE_SYSTEM_CASE_SENSITIVE GLOBAL PROPERTY "tkl::file_system::case_sensitive" 0)

        if (WIN32 OR (DEFINED TACKLELIB_FILE_SYSTEM_CASE_SENSITIVE AND NOT TACKLELIB_FILE_SYSTEM_CASE_SENSITIVE))
          foreach(TACKLELIB_TESTLIB_PATH_MATCH_FILTER IN LISTS TACKLELIB_TESTLIB_PATH_MATCH_FILTER_LIST)
            string(TOLOWER "${TESTS_ROOT}/${test_file_name}.cmake" _D089F11A_test_file_path_c)
            tkl_regex_to_lower("${TACKLELIB_TESTLIB_PATH_MATCH_FILTER}" _D089F11A_regex_path_match_filter_c)
            if ("${_D089F11A_test_file_path_c}" MATCHES "${_D089F11A_regex_path_match_filter_c}")
              unset(_D089F11A_test_file_path_c)
              unset(_D089F11A_regex_path_match_filter_c)
              include("${TESTS_ROOT}/${test_file_name}.cmake")
              break()
            endif()
          endforeach()
        else()
          foreach(TACKLELIB_TESTLIB_PATH_MATCH_FILTER IN LISTS TACKLELIB_TESTLIB_PATH_MATCH_FILTER_LIST)
            if ("${TESTS_ROOT}/${test_file_name}.cmake" MATCHES "${TACKLELIB_TESTLIB_PATH_MATCH_FILTER}")
              include("${TESTS_ROOT}/${test_file_name}.cmake")
              break()
            endif()
          endforeach()
        endif()
      endif()
    else()
      message(FATAL_ERROR "failed to include file: `${TESTS_ROOT}/${test_file_name}`")
    endif()
  endif()
endmacro()

function(tkl_testlib_test test_dir test_file_name)
  set(ret_code 0)

  if (NOT test_dir STREQUAL "" AND NOT test_dir STREQUAL .)
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

  tkl_get_global_prop(num_tests_run "tkl::testlib::num_tests_run" 1)
  if (num_tests_run STREQUAL "")
    set(num_tests_run 0)
  endif()
  math(EXPR num_tests_run ${num_tests_run}+1)
  set_property(GLOBAL PROPERTY "tkl::testlib::num_tests_run" ${num_tests_run})

  tkl_testlib_print_msg("[RUNNING ] `${test_file_dir_prefix}${test_file_name_ext}`...")

  tkl_make_ret_code_file_dir(ret_code_dir)

  tkl_get_global_prop(TACKLELIB_TESTLIB_TESTPROC_INDEX "tkl::testlib::testproc::index" 1)

  tkl_get_global_prop(TACKLELIB_TESTLIB_NUM_OVERALL_TESTS "tkl::testlib::num_overall_tests" 1)
  tkl_get_global_prop(TACKLELIB_TESTLIB_NUM_SUCCEEDED_TESTS "tkl::testlib::num_succeeded_tests" 1)
  tkl_get_global_prop(TACKLELIB_TESTLIB_NUM_FAILED_TESTS "tkl::testlib::num_failed_tests" 1)

  if (DEFINED TACKLELIB_TESTLIB_WORKING_DIR AND NOT TACKLELIB_TESTLIB_WORKING_DIR STREQUAL "" AND NOT TACKLELIB_TESTLIB_WORKING_DIR STREQUAL .)
    execute_process(
      COMMAND
        "${CMAKE_COMMAND}"
        "-DCMAKE_MODULE_PATH=${PROJECT_ROOT}/cmake"
        "-DPROJECT_ROOT=${PROJECT_ROOT}"
        "-DTESTS_ROOT=${TESTS_ROOT}"
        "-DTACKLELIB_TESTLIB_TESTPROC_RETCODE_DIR=${ret_code_dir}"
        "-DTACKLELIB_TESTLIB_TESTPROC_INDEX=${TACKLELIB_TESTLIB_TESTPROC_INDEX}"
        -P
        "${test_file_path}" ${TACKLELIB_TESTLIB_TEST_ARGS}
      WORKING_DIRECTORY
        "${TACKLELIB_TESTLIB_WORKING_DIR}"
      RESULT_VARIABLE
        TACKLELIB_TESTLIB_LAST_ERROR
    )
  else()
    execute_process(
      COMMAND
        "${CMAKE_COMMAND}"
        "-DCMAKE_MODULE_PATH=${PROJECT_ROOT}/cmake"
        "-DPROJECT_ROOT=${PROJECT_ROOT}"
        "-DTESTS_ROOT=${TESTS_ROOT}"
        "-DTACKLELIB_TESTLIB_TESTPROC_RETCODE_DIR=${ret_code_dir}"
        "-DTACKLELIB_TESTLIB_TESTPROC_INDEX=${TACKLELIB_TESTLIB_TESTPROC_INDEX}"
        -P
        "${test_file_path}" ${TACKLELIB_TESTLIB_TEST_ARGS}
      RESULT_VARIABLE
        TACKLELIB_TESTLIB_LAST_ERROR
    )
  endif()

  set_property(GLOBAL PROPERTY "tkl::testlib::last_error" "${TACKLELIB_TESTLIB_LAST_ERROR}")

  if (NOT TACKLELIB_TESTLIB_LAST_ERROR)
    tkl_get_ret_code_from_file_dir("${ret_code_dir}" TACKLELIB_TESTLIB_LAST_ERROR)
  endif()

  tkl_remove_ret_code_file_dir("${ret_code_dir}")

  math(EXPR TACKLELIB_TESTLIB_NUM_OVERALL_TESTS "${TACKLELIB_TESTLIB_NUM_OVERALL_TESTS}+1")

  if (TACKLELIB_TESTLIB_LAST_ERROR EQUAL 0)
    math(EXPR TACKLELIB_TESTLIB_NUM_SUCCEEDED_TESTS "${TACKLELIB_TESTLIB_NUM_SUCCEEDED_TESTS}+1")
    tkl_testlib_print_msg("[   OK   ] `${test_file_dir_prefix}${test_file_name_ext}`")
  else()
    math(EXPR TACKLELIB_TESTLIB_NUM_FAILED_TESTS "${TACKLELIB_TESTLIB_NUM_FAILED_TESTS}+1")
    tkl_testlib_print_msg("[ FAILED ] `${test_file_dir_prefix}${test_file_name_ext}`")
  endif()

  set_property(GLOBAL PROPERTY "tkl::testlib::num_overall_tests" "${TACKLELIB_TESTLIB_NUM_OVERALL_TESTS}")
  set_property(GLOBAL PROPERTY "tkl::testlib::num_succeeded_tests" "${TACKLELIB_TESTLIB_NUM_SUCCEEDED_TESTS}")
  set_property(GLOBAL PROPERTY "tkl::testlib::num_failed_tests" "${TACKLELIB_TESTLIB_NUM_FAILED_TESTS}")

  math(EXPR TACKLELIB_TESTLIB_TESTPROC_INDEX "${TACKLELIB_TESTLIB_TESTPROC_INDEX}+1")

  set_property(GLOBAL PROPERTY "tkl::testlib::testproc::index" "${TACKLELIB_TESTLIB_TESTPROC_INDEX}")
endfunction()

endif()
