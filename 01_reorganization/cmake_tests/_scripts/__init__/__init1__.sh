#!/bin/bash

# Script can be ONLY included by "source" command.
if [[ -n "$BASH" && (-z "$BASH_LINENO" || BASH_LINENO[0] -gt 0) && "$TACKLELIB_CMAKE_TESTS_SCRIPTS_INIT1_DIR" != "$BASH_SOURCE_DIR" ]]; then 

tkl_include "__init0__.sh" || return $?

TACKLELIB_CMAKE_TESTS_SCRIPTS_INIT1_DIR="$BASH_SOURCE_DIR" # including guard

# optional compare in case of generator script
if (( IN_GENERATOR_SCRIPT )); then
  tkl_call_and_print_if "(( INIT_VERBOSE ))" CheckConfigVersion -optional_system_file_instance -optional_user_file_instance \
    "$CMAKE_CONFIG_VARS_SYSTEM_FILE_IN" "$CMAKE_CONFIG_VARS_SYSTEM_FILE" || return $?
else
  tkl_call_and_print_if "(( INIT_VERBOSE ))" CheckConfigVersion \
    "$CMAKE_CONFIG_VARS_SYSTEM_FILE_IN" "$CMAKE_CONFIG_VARS_SYSTEM_FILE" || return $?
fi

fi
