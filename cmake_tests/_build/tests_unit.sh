#!/bin/bash

# Script ONLY for execution.
if [[ -n "$BASH" && (-z "$BASH_LINENO" || BASH_LINENO[0] -eq 0) ]]; then

source '/bin/bash_tacklelib' || exit $?
tkl_include '__init__/__init__.sh' || tkl_abort_include

# no local logging if nested call
(( ! IMPL_MODE && ! NEST_LVL )) && {
  export IMPL_MODE=1
  exec 3>&1 4>&2
  tkl_push_trap 'exec 2>&4 1>&3' EXIT

  # date time request base on: https://stackoverflow.com/questions/1401482/yyyy-mm-dd-format-date-in-shell-script/1401495#1401495
  #

  # RANDOM instead of milliseconds
  case $BASH_VERSION in
    # < 4.2
    [123].* | 4.[01] | 4.0* | 4.1[^0-9]*)
      PROJECT_LOG_FILE_NAME_SUFFIX=$(date "+%Y'%m'%d_%H'%M'%S''")$(( RANDOM % 1000 ))
      ;;
    # >= 4.2
    *)
      printf -v PROJECT_LOG_FILE_NAME_SUFFIX "%(%Y'%m'%d_%H'%M'%S'')T$(( RANDOM % 1000 ))" -1
      ;;
  esac

  PROJECT_LOG_DIR="$PROJECT_LOG_ROOT/$PROJECT_LOG_FILE_NAME_SUFFIX.${BASH_SOURCE_FILE_NAME%[.]*}"
  PROJECT_LOG_FILE="$PROJECT_LOG_DIR/${PROJECT_LOG_FILE_NAME_SUFFIX}.${BASH_SOURCE_FILE_NAME%[.]*}.log"

  [[ ! -e "$PROJECT_LOG_DIR" ]] && { mkdir -p "$PROJECT_LOG_DIR" || tkl_abort 11; }

  # stdout+stderr redirection into the same log file with handles restore
  {
  {
  {
    exec $0 "$@" 2>&1 1>&8
  } | tee -a "$PROJECT_LOG_FILE" 1>&9
  } 8>&1 | tee -a "$PROJECT_LOG_FILE"
  } 9>&2

  exit $?
}

(( NEST_LVL++ ))


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
