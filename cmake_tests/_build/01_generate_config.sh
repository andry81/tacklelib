#!/bin/bash

# Configuration variable files generator script.

# Script ONLY for execution.
[[ -n "$BASH" && (-z "$BASH_LINENO" || BASH_LINENO[0] -eq 0) ]] || exit 0

(( SOURCE_TACKLELIB_BASH_TACKLELIB_SH )) || source bash_tacklelib || exit 255

tkl_include_or_abort '__init__/__init__.sh'

tkl_exec_project_logging

# optional compare in case of generator script
tkl_call_and_print_if "(( INIT_VERBOSE ))" CheckConfigVersion -optional_compare \
  "$CMAKE_CONFIG_VARS_SYSTEM_FILE_IN" "$CMAKE_CONFIG_VARS_SYSTEM_FILE" || tkl_exit $?

GenerateConfig || tkl_exit $?

tkl_exit
