#!/bin/bash

# Script can be ONLY included by "source" command.
if [[ -n "$BASH" && (-z "$BASH_LINENO" || BASH_LINENO[0] -gt 0) && "$TACKLELIB_SCRIPTS_INIT1_DIR" != "$BASH_SOURCE_DIR" ]]; then 

function __init1__()
{
  tkl_include '__init0__.sh' || tkl_abort_include

  tkl_declare_global TACKLELIB_SCRIPTS_INIT1_DIR "$BASH_SOURCE_DIR" # including guard

  # optional compare in case of generator script
  tkl_call_and_print_if "(( INIT_VERBOSE ))" CheckConfigVersion "$IN_GENERATOR_SCRIPT" \
    "$CONFIG_VARS_SYSTEM_FILE_IN" "$CONFIG_VARS_SYSTEM_FILE" \
    "$CONFIG_VARS_USER_FILE_IN" "$CONFIG_VARS_USER_FILE" || tkl_abort_include
}

__init1__

fi
