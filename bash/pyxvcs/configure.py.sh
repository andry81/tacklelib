#!/bin/bash

# Script both for execution and inclusion.
if [[ -n "$BASH" ]]; then

source '/bin/bash_tacklelib' || exit $?
tkl_include '__init__/__init__.sh' || tkl_abort_include

function pyxvcs_configure()
{
  local i
  for i in CMDOP_PROJECT_ROOT PYTHON_EXE_PATH PYXVCS_PYTHON_ROOT; do
    if [[ -z "$i" ]]; then
      echo "${FUNCNAME[0]}: error: \'$i\` variable is not defined." >&2
      exit 255
    fi
  done

  tkl_exec_project_logging

  # always calls as an external process without an inprocess call optimization
  tkl_call "$PYTHON_EXE_PATH" "$PYXVCS_PYTHON_ROOT/pyxvcs/configure.xsh" "$@"
  tkl_set_error $?

  exit $tkl__last_error
}

if [[ -z "$BASH_LINENO" || BASH_LINENO[0] -eq 0 ]]; then
  # Script was not included, then execute it.
  pyxvcs_configure "$@"
fi

fi
