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
  get_property(TACKLELIB_TESTLIB_INITED GLOBAL PROPERTY "tkl::testlib::inited")

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
  get_property(TACKLELIB_TESTLIB_PATH_MATCH_FILTER_LIST GLOBAL PROPERTY "tkl::testlib::path_match_filter")
  get_property(TACKLELIB_TESTLIB_LAST_ENTER_DIR GLOBAL PROPERTY "tkl::testlib::last_enter_dir")

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

  tkl_pushset_prop_to_stack(GLOBAL "tkl::testlib::last_enter_dir" "${test_dir_path}")
  get_property(TACKLELIB_TESTLIB_LAST_ENTER_DIR GLOBAL PROPERTY "tkl::testlib::last_enter_dir")

  get_property(TACKLELIB_TESTLIB_NUM_OVERALL_TESTS GLOBAL PROPERTY "tkl::testlib::num_overall_tests")
  get_property(TACKLELIB_TESTLIB_NUM_SUCCEEDED_TESTS GLOBAL PROPERTY "tkl::testlib::num_succeeded_tests")
  get_property(TACKLELIB_TESTLIB_NUM_FAILED_TESTS GLOBAL PROPERTY "tkl::testlib::num_failed_tests")

  set(TACKLELIB_TESTLIB_NUM_OVERALL_TESTS 0)
  set(TACKLELIB_TESTLIB_NUM_SUCCEEDED_TESTS 0)
  set(TACKLELIB_TESTLIB_NUM_FAILED_TESTS 0)

  tkl_pushset_prop_to_stack(GLOBAL "tkl::testlib::num_overall_tests" ${TACKLELIB_TESTLIB_NUM_OVERALL_TESTS})
  tkl_pushset_prop_to_stack(GLOBAL "tkl::testlib::num_succeeded_tests" ${TACKLELIB_TESTLIB_NUM_SUCCEEDED_TESTS})
  tkl_pushset_prop_to_stack(GLOBAL "tkl::testlib::num_failed_tests" ${TACKLELIB_TESTLIB_NUM_FAILED_TESTS})

  message("---\nEntering directory: `${TACKLELIB_TESTLIB_LAST_ENTER_DIR}`...")

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

  # reread testlib states
  get_property(TACKLELIB_TESTLIB_NUM_OVERALL_TESTS_CHILDREN GLOBAL PROPERTY "tkl::testlib::num_overall_tests")
  get_property(TACKLELIB_TESTLIB_NUM_SUCCEEDED_TESTS_CHILDREN GLOBAL PROPERTY "tkl::testlib::num_succeeded_tests")
  get_property(TACKLELIB_TESTLIB_NUM_FAILED_TESTS_CHILDREN GLOBAL PROPERTY "tkl::testlib::num_failed_tests")

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

  message("Leaving directory: `${TACKLELIB_TESTLIB_LAST_ENTER_DIR}`: failed/succeeded of overall: ${TACKLELIB_TESTLIB_NUM_FAILED_TESTS_CHILDREN}/${TACKLELIB_TESTLIB_NUM_SUCCEEDED_TESTS_CHILDREN} of ${TACKLELIB_TESTLIB_NUM_OVERALL_TESTS_CHILDREN}\n---\n")

  tkl_pop_prop_from_stack(. GLOBAL "tkl::testlib::last_enter_dir")
  get_property(TACKLELIB_TESTLIB_LAST_ENTER_DIR GLOBAL PROPERTY "tkl::testlib::last_enter_dir")
endfunction()

macro(tkl_testlib_exit)
  get_property(TACKLELIB_TESTLIB_NUM_OVERALL_TESTS GLOBAL PROPERTY "tkl::testlib::num_overall_tests")
  get_property(TACKLELIB_TESTLIB_NUM_SUCCEEDED_TESTS GLOBAL PROPERTY "tkl::testlib::num_succeeded_tests")
  get_property(TACKLELIB_TESTLIB_NUM_FAILED_TESTS GLOBAL PROPERTY "tkl::testlib::num_failed_tests")

  message("RESULTS: failed/succeeded of overall: ${TACKLELIB_TESTLIB_NUM_FAILED_TESTS}/${TACKLELIB_TESTLIB_NUM_SUCCEEDED_TESTS} of ${TACKLELIB_TESTLIB_NUM_OVERALL_TESTS}\n===\n")
endmacro()

macro(tkl_testlib_include test_dir test_file_name)
  get_property(TACKLELIB_TESTLIB_LAST_ENTER_DIR GLOBAL PROPERTY "tkl::testlib::last_enter_dir")
  get_property(TACKLELIB_TESTLIB_PATH_MATCH_FILTER_LIST GLOBAL PROPERTY "tkl::testlib::path_match_filter")

  if (NOT test_dir STREQUAL "" AND NOT test_dir STREQUAL .)
    if (EXISTS "${TESTS_ROOT}/${test_dir}/${test_file_name}" AND
        NOT IS_DIRECTORY "${TESTS_ROOT}/${test_dir}/${test_file_name}")
      if (TACKLELIB_TESTLIB_PATH_MATCH_FILTER_LIST STREQUAL "")
        include("${TESTS_ROOT}/${test_dir}/${test_file_name}")
      else()
        foreach(TACKLELIB_TESTLIB_PATH_MATCH_FILTER IN LISTS TACKLELIB_TESTLIB_PATH_MATCH_FILTER_LIST)
          if ("${TESTS_ROOT}/${test_dir}/${test_file_name}" MATCHES "${TACKLELIB_TESTLIB_PATH_MATCH_FILTER}")
            include("${TESTS_ROOT}/${test_dir}/${test_file_name}")
            break()
          endif()
        endforeach()
      endif()
    elseif (EXISTS "${TESTS_ROOT}/${test_dir}/${test_file_name}.cmake" AND
        NOT IS_DIRECTORY "${TESTS_ROOT}/${test_dir}/${test_file_name}.cmake")
      if (TACKLELIB_TESTLIB_PATH_MATCH_FILTER_LIST STREQUAL "")
        include("${TESTS_ROOT}/${test_dir}/${test_file_name}.cmake")
      else()
        foreach(TACKLELIB_TESTLIB_PATH_MATCH_FILTER IN LISTS TACKLELIB_TESTLIB_PATH_MATCH_FILTER_LIST)
          if ("${TESTS_ROOT}/${test_dir}/${test_file_name}.cmake" MATCHES "${TACKLELIB_TESTLIB_PATH_MATCH_FILTER}")
            include("${TESTS_ROOT}/${test_dir}/${test_file_name}.cmake")
            break()
          endif()
        endforeach()
      endif()
    else()
      message(FATAL_ERROR "can not include `${TESTS_ROOT}/${test_dir}/${test_file_name}` file")
    endif()
  else()
    if (EXISTS "${TESTS_ROOT}/${test_file_name}" AND
        NOT IS_DIRECTORY "${TESTS_ROOT}/${test_file_name}")
      if (TACKLELIB_TESTLIB_PATH_MATCH_FILTER_LIST STREQUAL "")
        include("${TESTS_ROOT}/${test_file_name}")
      else()
        foreach(TACKLELIB_TESTLIB_PATH_MATCH_FILTER IN LISTS TACKLELIB_TESTLIB_PATH_MATCH_FILTER_LIST)
          if ("${TESTS_ROOT}/${test_file_name}" MATCHES "${TACKLELIB_TESTLIB_PATH_MATCH_FILTER}")
            include("${TESTS_ROOT}/${test_file_name}")
            break()
          endif()
        endforeach()
      endif()
    elseif (EXISTS "${TESTS_ROOT}/${test_file_name}.cmake" AND
        NOT IS_DIRECTORY "${TESTS_ROOT}/${test_file_name}.cmake")
      if (TACKLELIB_TESTLIB_PATH_MATCH_FILTER_LIST STREQUAL "")
        include("${TESTS_ROOT}/${test_file_name}.cmake")
      else()
        foreach(TACKLELIB_TESTLIB_PATH_MATCH_FILTER IN LISTS TACKLELIB_TESTLIB_PATH_MATCH_FILTER_LIST)
          if ("${TESTS_ROOT}/${test_file_name}.cmake" MATCHES "${TACKLELIB_TESTLIB_PATH_MATCH_FILTER}")
            include("${TESTS_ROOT}/${test_file_name}.cmake")
            break()
          endif()
        endforeach()
      endif()
    else()
      message(FATAL_ERROR "can not include `${TESTS_ROOT}/${test_file_name}` file")
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

  message("[RUNNING ] `${test_file_dir_prefix}${test_file_name_ext}`...")

  tkl_make_ret_code_file_dir(ret_code_dir)

  get_property(TACKLELIB_TESTLIB_TESTPROC_INDEX GLOBAL PROPERTY "tkl::testlib::testproc::index")

  get_property(TACKLELIB_TESTLIB_NUM_OVERALL_TESTS GLOBAL PROPERTY "tkl::testlib::num_overall_tests")
  get_property(TACKLELIB_TESTLIB_NUM_SUCCEEDED_TESTS GLOBAL PROPERTY "tkl::testlib::num_succeeded_tests")
  get_property(TACKLELIB_TESTLIB_NUM_FAILED_TESTS GLOBAL PROPERTY "tkl::testlib::num_failed_tests")

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
    message("[   OK   ] `${test_file_dir_prefix}${test_file_name_ext}`")
  else()
    math(EXPR TACKLELIB_TESTLIB_NUM_FAILED_TESTS "${TACKLELIB_TESTLIB_NUM_FAILED_TESTS}+1")
    message("[ FAILED ] `${test_file_dir_prefix}${test_file_name_ext}`")
  endif()

  set_property(GLOBAL PROPERTY "tkl::testlib::num_overall_tests" "${TACKLELIB_TESTLIB_NUM_OVERALL_TESTS}")
  set_property(GLOBAL PROPERTY "tkl::testlib::num_succeeded_tests" "${TACKLELIB_TESTLIB_NUM_SUCCEEDED_TESTS}")
  set_property(GLOBAL PROPERTY "tkl::testlib::num_failed_tests" "${TACKLELIB_TESTLIB_NUM_FAILED_TESTS}")

  math(EXPR TACKLELIB_TESTLIB_TESTPROC_INDEX "${TACKLELIB_TESTLIB_TESTPROC_INDEX}+1")

  set_property(GLOBAL PROPERTY "tkl::testlib::testproc::index" "${TACKLELIB_TESTLIB_TESTPROC_INDEX}")
endfunction()

endif()
