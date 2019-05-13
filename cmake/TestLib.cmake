# include guard to speedup inclusion
if (NOT DEFINED TESTLIB_INCLUDE_DEFINED)
set(TESTLIB_INCLUDE_DEFINED 1)

include(Std)
include(ReturnCodeFile)

set(TESTLIB_INITED 0)

function(TestLib_Init)
  if (TESTLIB_INITED)
    return()
  endif()

  set(TESTLIB_INITED 1 PARENT_SCOPE)
  set(TESTLIB_WORKING_DIR . PARENT_SCOPE)
  set(TESTLIB_LAST_ERROR -1 PARENT_SCOPE)

  set(TESTLIB_NUM_OVERALL_TESTS 0 PARENT_SCOPE)
  set(TESTLIB_NUM_SUCCEEDED_TESTS 0 PARENT_SCOPE)
  set(TESTLIB_NUM_FAILED_TESTS 0 PARENT_SCOPE)

  set(TESTLIB_LAST_ENTER_DIR "" PARENT_SCOPE)

  set(TESTLIB_TEST_ARGS "" PARENT_SCOPE)
  set(TESTLIB_TESTPROC_INDEX 0 PARENT_SCOPE)

  if (NOT DEFINED TESTS_ROOT)
    message(FATAL_ERROR "TESTS_ROOT must be defined")
  endif()

  if (NOT DEFINED TEST_SCRIPT_FILE_NAME)
    message(FATAL_ERROR "TEST_SCRIPT_FILE_NAME must be defined")
  endif()

  set(TESTLIB_INITED 1 PARENT_SCOPE)
endfunction()

macro(TestLib_SetWorkingDir dir)
  set(TESTLIB_WORKING_DIR "${dir}")
endmacro()

macro(TestLib_SetTestArgs)
  set(TESTLIB_TEST_ARGS "${ARGN}")
endmacro()

function(TestLib_Directory test_dir)
  # Algorithm:
  #   1. Iterate not recursively over all `*.include.cmake` files and
  #      call to `TestLib_Include` function on each file, then
  #      if at least one is iterated then
  #      exit the algorithm.
  #   2. Iterate non recursively over all subdirectories and
  #      call to the algorithm recursively on each subdirectory, then
  #      continue.
  #   3. Iterate not recursively over all `*.test.cmake` files and
  #      call to `TestLib_Test` function on each file, then
  #      exit the algorithm.
  #

  if (TESTLIB_LAST_ENTER_DIR)
    if (NOT test_dir STREQUAL "" AND NOT test_dir STREQUAL .)
      set(test_dir_path "${TESTLIB_LAST_ENTER_DIR}/${test_dir}")
    else()
      set(test_dir_path "${TESTLIB_LAST_ENTER_DIR}")
    endif()
  else()
    if (NOT test_dir STREQUAL "" AND NOT test_dir STREQUAL .)
      set(test_dir_path "${test_dir}")
    else()
      set(test_dir_path ".")
    endif()
  endif()

  set(TESTLIB_LAST_ERROR -1) # always set to special not zero value to provoke test to fail by default
  set(TESTLIB_LAST_ENTER_DIR "${test_dir_path}")

  set(TESTLIB_NUM_OVERALL_TESTS_PARENT "${TESTLIB_NUM_OVERALL_TESTS}")
  set(TESTLIB_NUM_SUCCEEDED_TESTS_PARENT "${TESTLIB_NUM_SUCCEEDED_TESTS}")
  set(TESTLIB_NUM_FAILED_TESTS_PARENT "${TESTLIB_NUM_FAILED_TESTS}")

  set(TESTLIB_NUM_OVERALL_TESTS 0)
  set(TESTLIB_NUM_SUCCEEDED_TESTS 0)
  set(TESTLIB_NUM_FAILED_TESTS 0)

  message("---\nEntering directory: `${TESTLIB_LAST_ENTER_DIR}`...")

  file(GLOB include_files
    LIST_DIRECTORIES false
    RELATIVE "${TESTS_ROOT}/${TESTLIB_LAST_ENTER_DIR}"
    "${TESTS_ROOT}/${TESTLIB_LAST_ENTER_DIR}/*.include.cmake"
  )

  if (include_files)
    foreach(include_file IN LISTS include_files)
      TestLib_Include("${TESTLIB_LAST_ENTER_DIR}" "${include_file}")
    endforeach()
  else()
    file(GLOB all_files
      LIST_DIRECTORIES true
      RELATIVE "${TESTS_ROOT}/${TESTLIB_LAST_ENTER_DIR}"
      "${TESTS_ROOT}/${TESTLIB_LAST_ENTER_DIR}/*"
    )

    foreach(file_name IN LISTS all_files)
      if (NOT IS_DIRECTORY "${TESTS_ROOT}/${TESTLIB_LAST_ENTER_DIR}/${file_name}")
        continue()
      endif()

      TestLib_Directory("${file_name}")
    endforeach()

    file(GLOB test_files
      LIST_DIRECTORIES false
      RELATIVE "${TESTS_ROOT}/${TESTLIB_LAST_ENTER_DIR}"
      "${TESTS_ROOT}/${TESTLIB_LAST_ENTER_DIR}/*.test.cmake"
    )

    foreach(test_file IN LISTS test_files)
      TestLib_Test("${TESTLIB_LAST_ENTER_DIR}" "${test_file}")
    endforeach()
  endif()

  math(EXPR TESTLIB_NUM_FAILED_TESTS_PARENT "${TESTLIB_NUM_FAILED_TESTS_PARENT}+${TESTLIB_NUM_FAILED_TESTS}")
  math(EXPR TESTLIB_NUM_SUCCEEDED_TESTS_PARENT "${TESTLIB_NUM_SUCCEEDED_TESTS_PARENT}+${TESTLIB_NUM_SUCCEEDED_TESTS}")
  math(EXPR TESTLIB_NUM_OVERALL_TESTS_PARENT "${TESTLIB_NUM_OVERALL_TESTS_PARENT}+${TESTLIB_NUM_OVERALL_TESTS}")

  # NOTE: does not change the current function scope variables!
  set(TESTLIB_NUM_FAILED_TESTS "${TESTLIB_NUM_FAILED_TESTS_PARENT}" PARENT_SCOPE)
  set(TESTLIB_NUM_SUCCEEDED_TESTS "${TESTLIB_NUM_SUCCEEDED_TESTS_PARENT}" PARENT_SCOPE)
  set(TESTLIB_NUM_OVERALL_TESTS "${TESTLIB_NUM_OVERALL_TESTS_PARENT}" PARENT_SCOPE)

  set(TESTLIB_TESTPROC_INDEX "${TESTLIB_TESTPROC_INDEX}" PARENT_SCOPE)

  message("Leaving directory: `${TESTLIB_LAST_ENTER_DIR}`: failed/succeeded of overall: ${TESTLIB_NUM_FAILED_TESTS}/${TESTLIB_NUM_SUCCEEDED_TESTS} of ${TESTLIB_NUM_OVERALL_TESTS}\n---\n")
endfunction()

macro(TestLib_Include test_dir test_file_name)
  if (NOT test_dir STREQUAL "" AND NOT test_dir STREQUAL .)
    if (EXISTS "${TESTS_ROOT}/${test_dir}/${test_file_name}" AND
        NOT IS_DIRECTORY "${TESTS_ROOT}/${test_dir}/${test_file_name}")
      include("${TESTS_ROOT}/${test_dir}/${test_file_name}")
    elseif (EXISTS "${TESTS_ROOT}/${test_dir}/${test_file_name}.cmake" AND
        NOT IS_DIRECTORY "${TESTS_ROOT}/${test_dir}/${test_file_name}.cmake")
      include("${TESTS_ROOT}/${test_dir}/${test_file_name}.cmake")
    else()
      message(FATAL_ERROR "can not include `${TESTS_ROOT}/${test_dir}/${test_file_name}` file")
    endif()
  else()
    if (EXISTS "${TESTS_ROOT}/${test_file_name}" AND
        NOT IS_DIRECTORY "${TESTS_ROOT}/${test_file_name}")
      include("${TESTS_ROOT}/${test_file_name}")
    elseif (EXISTS "${TESTS_ROOT}/${test_file_name}.cmake" AND
        NOT IS_DIRECTORY "${TESTS_ROOT}/${test_file_name}.cmake")
      include("${TESTS_ROOT}/${test_file_name}.cmake")
    else()
      message(FATAL_ERROR "can not include `${TESTS_ROOT}/${test_file_name}` file")
    endif()
  endif()
endmacro()

function(TestLib_Test test_dir test_file_name)
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

  CreateReturnCodeFile(ret_code_dir)

  if (DEFINED TESTLIB_WORKING_DIR AND NOT TESTLIB_WORKING_DIR STREQUAL "" AND NOT TESTLIB_WORKING_DIR STREQUAL .)
    execute_process(
      COMMAND
        "${CMAKE_COMMAND}"
        "-DCMAKE_MODULE_PATH=${PROJECT_ROOT}/cmake;${PROJECT_ROOT}/cmake/_3dparty"
        "-DPROJECT_ROOT=${PROJECT_ROOT}"
        "-DTESTS_ROOT=${TESTS_ROOT}"
        "-DTESTLIB_TESTPROC_RETCODE_DIR=${ret_code_dir}"
        "-DTESTLIB_TESTPROC_INDEX=${TESTLIB_TESTPROC_INDEX}"
        -P
        "${test_file_path}" ${TESTLIB_TEST_ARGS}
      WORKING_DIRECTORY
        "${TESTLIB_WORKING_DIR}"
      RESULT_VARIABLE
        TESTLIB_LAST_ERROR
    )
  else()
    execute_process(
      COMMAND
        "${CMAKE_COMMAND}"
        "-DCMAKE_MODULE_PATH=${PROJECT_ROOT}/cmake;${PROJECT_ROOT}/cmake/_3dparty"
        "-DPROJECT_ROOT=${PROJECT_ROOT}"
        "-DTESTS_ROOT=${TESTS_ROOT}"
        "-DTESTLIB_TESTPROC_RETCODE_DIR=${ret_code_dir}"
        "-DTESTLIB_TESTPROC_INDEX=${TESTLIB_TESTPROC_INDEX}"
        -P
        "${test_file_path}" ${TESTLIB_TEST_ARGS}
      RESULT_VARIABLE
        TESTLIB_LAST_ERROR
    )
  endif()

  set(TESTLIB_LAST_ERROR ${TESTLIB_LAST_ERROR} PARENT_SCOPE)

  if (NOT TESTLIB_LAST_ERROR)
    GetReturnCodeFromFile("${ret_code_dir}" TESTLIB_LAST_ERROR)
  endif()

  RemoveReturnCodeFile("${ret_code_dir}")

  math(EXPR TESTLIB_NUM_OVERALL_TESTS "${TESTLIB_NUM_OVERALL_TESTS}+1")

  if (TESTLIB_LAST_ERROR EQUAL 0)
    math(EXPR TESTLIB_NUM_SUCCEEDED_TESTS "${TESTLIB_NUM_SUCCEEDED_TESTS}+1")
    message("[   OK   ] `${test_file_dir_prefix}${test_file_name_ext}`")
  else()
    math(EXPR TESTLIB_NUM_FAILED_TESTS "${TESTLIB_NUM_FAILED_TESTS}+1")
    message("[ FAILED ] `${test_file_dir_prefix}${test_file_name_ext}`")
  endif()

  set(TESTLIB_NUM_OVERALL_TESTS "${TESTLIB_NUM_OVERALL_TESTS}" PARENT_SCOPE)
  set(TESTLIB_NUM_SUCCEEDED_TESTS "${TESTLIB_NUM_SUCCEEDED_TESTS}" PARENT_SCOPE)
  set(TESTLIB_NUM_FAILED_TESTS "${TESTLIB_NUM_FAILED_TESTS}" PARENT_SCOPE)

  math(EXPR TESTLIB_TESTPROC_INDEX "${TESTLIB_TESTPROC_INDEX}+1")
  set(TESTLIB_TESTPROC_INDEX "${TESTLIB_TESTPROC_INDEX}" PARENT_SCOPE)
endfunction()

endif()
