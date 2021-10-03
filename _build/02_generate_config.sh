#!/bin/bash

# Configuration variable files generator script.

# Script ONLY for execution.
if [[ -n "$BASH" && (-z "$BASH_LINENO" || BASH_LINENO[0] -eq 0) ]]; then

source '/bin/bash_tacklelib' || exit $?
tkl_include '__init__/__init__.sh' || tkl_abort_include

tkl_exec_project_logging

# optional compare in case of generator script
tkl_call_and_print_if "(( INIT_VERBOSE ))" CheckConfigVersion 1 \
  "$CONFIG_VARS_SYSTEM_FILE_IN" "$CONFIG_VARS_SYSTEM_FILE" \
  "$CONFIG_VARS_USER_FILE_IN" "$CONFIG_VARS_USER_FILE" || tkl_abort $?

GenerateConfig || tkl_exit $?

tkl_exit

fi
