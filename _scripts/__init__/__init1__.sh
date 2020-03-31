#!/bin/bash

# CAUTION:
#  In case of usage the QtCreator there is set of special broken cases you have to avoid:
#  1. Invalid characters in paths: `(`, `)` and `.`.
#  2. Non english locale in paths.

# Script can be ONLY included by "source" command.
if [[ -n "$BASH" && (-z "$BASH_LINENO" || BASH_LINENO[0] -gt 0) && (-z "$SOURCE_ROOT_INIT1_SH" || SOURCE_ROOT_INIT1_SH -eq 0) ]]; then 

SOURCE_ROOT_INIT1_SH=1 # including guard

tkl_include "__init0__.sh" || return $?

# optional compare in case of generator script
tkl_call_and_print_if "(( INIT_VERBOSE ))" CheckConfigVersion "$IN_GENERATOR_SCRIPT" \
  "$CONFIG_VARS_SYSTEM_FILE_IN" "$CONFIG_VARS_SYSTEM_FILE" \
  "$CONFIG_VARS_USER_FILE_IN" "$CONFIG_VARS_USER_FILE" || return $?

fi
