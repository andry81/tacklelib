#!/bin/bash

# Script ONLY for execution.
if [[ -n "$BASH" && (-z "$BASH_LINENO" || BASH_LINENO[0] -eq 0) ]]; then

source '/bin/bash_tacklelib' || exit $?
tkl_include '__init__/__init__.sh' || tkl_abort_include

tkl_exec_project_logging

tkl_call_and_print_if "(( INIT_VERBOSE ))" CheckConfigVersion \
  "$CMAKE_CONFIG_VARS_SYSTEM_FILE_IN" "$CMAKE_CONFIG_VARS_SYSTEM_FILE" || tkl_exit $?

tkl_include "$TACKLELIB_BASH_ROOT/tacklelib/tools/cmake/set_vars_from_files.sh" || tkl_abort_include

UpdateOsName

# preload configuration files only to make some checks
tkl_call set_vars_from_files \
  "${CMAKE_CONFIG_VARS_SYSTEM_FILE//;/\\;}" "$OS_NAME" . . . ":" \
  --exclude_vars_filter "TESTS_PROJECT_ROOT" \
  --ignore_late_expansion_statements || tkl_exit $?

tkl_pushd "$TESTS_PROJECT_ROOT/unit" && {
  IFS=$':\t\r\n'; for pytest in $PYTESTS_LIST; do
    tkl_call "$PYTEST_EXE_PATH" "$@" "$pytest" || { tkl_popd; tkl_exit; }
  done
  tkl_popd
}

tkl_exit

fi
