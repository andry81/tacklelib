#!/bin/bash

# Script ONLY for execution.
if [[ -n "$BASH" && (-z "$BASH_LINENO" || BASH_LINENO[0] -eq 0) ]]; then

source '/bin/bash_tacklelib' || exit $?
tkl_include '__init__/__init__.sh' || tkl_abort_include

tkl_exec_project_logging

tkl_call_and_print_if "(( INIT_VERBOSE ))" CheckConfigVersion \
  "$CMAKE_CONFIG_VARS_SYSTEM_FILE_IN" "$CMAKE_CONFIG_VARS_SYSTEM_FILE" || tkl_exit $?

tkl_call cmake \
  "-DCMAKE_MODULE_PATH=${TESTS_PROJECT_ROOT//\\//};${TACKLELIB_CMAKE_ROOT//\\//}" \
  "-DTESTS_PROJECT_ROOT=${TESTS_PROJECT_ROOT//\\//}" \
  "-DTESTS_PROJECT_OUTPUT_CONFIG_ROOT=${TESTS_PROJECT_OUTPUT_CONFIG_ROOT//\\//}" \
  "-DTACKLELIB_TESTLIB_TESTSCRIPT_FILE=${TESTS_PROJECT_ROOT//\\//}/${BASH_SOURCE_FILE_NAME%[.]*}.cmake" \
  "-DTACKLELIB_TESTLIB_ROOT=${TACKLELIB_CMAKE_ROOT//\\//}/tacklelib/testlib" \
  -P \
  "${TACKLELIB_CMAKE_ROOT//\\//}/tacklelib/testlib/tools/RunTestLib.cmake" \
  "$@" || tkl_exit $?

tkl_exit

fi