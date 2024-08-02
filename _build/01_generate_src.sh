#!/bin/bash

# Source files generator script.

# Script ONLY for execution.
[[ -n "$BASH" && (-z "$BASH_LINENO" || BASH_LINENO[0] -eq 0) ]] || return 0 || exit 0 # exit to avoid continue if the return can not be called

if [[ -z "$SOURCE_TACKLELIB_BASH_TACKLELIB_SH" || SOURCE_TACKLELIB_BASH_TACKLELIB_SH -eq 0 ]]; then
  # builtin search
  for BASH_SOURCE_DIR in '/usr/local/bin' '/usr/bin' '/bin'; do
    if [[ -f "$BASH_SOURCE_DIR/bash_tacklelib" ]]; then
      source "$BASH_SOURCE_DIR/bash_tacklelib" || exit $?
      break
    fi
  done
fi

tkl_include_or_abort '__init__/__init__.sh'

# workaround for the bug in the "[@]:i" expression under the bash version lower than 4.1
IFS=$' \t\r\n' \
  tkl_make_command_line '' 1 "$@"
echo -e ">$RETURN_VALUE\n"

tkl_exec_project_logging

tkl_mk_01_generate_src \
  "$TACKLELIB_PROJECT_ROOT" \
  "$TACKLELIB_PROJECT_INPUT_CONFIG_ROOT/_build/${BASH_SOURCE_FILE_NAME%[.]*}/gen_file_list.in" \
  "$TACKLELIB_PROJECT_INPUT_CONFIG_ROOT/_build/${BASH_SOURCE_FILE_NAME%[.]*}/cmd_list.${BASH_SOURCE_FILE_NAME##*[.]}.in" || tkl_exit

tkl_exit
