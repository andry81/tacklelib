#!/bin/bash

# Source files generator script.

# Script ONLY for execution.
if [[ -n "$BASH" && (-z "$BASH_LINENO" || BASH_LINENO[0] -eq 0) ]]; then

source '/bin/bash_tacklelib' || exit $?
tkl_include '__init__/__init__.sh' || tkl_abort_include

# workaround for the bug in the "[@]:i" expression under the bash version lower than 4.1
IFS=$' \t\r\n' \
  tkl_make_command_line '' 1 "$@"
echo -e ">$RETURN_VALUE\n"

tkl_exec_project_logging

GenerateSrc || tkl_exit $?

tkl_exit

fi
