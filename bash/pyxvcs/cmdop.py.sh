#!/bin/bash

# Script both for execution and inclusion.
[[ -n "$BASH" ]] || return 0 || exit 0 # exit to avoid continue if the return can not be called

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

function pyxvcs_cmdop()
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
  tkl_call "$PYTHON_EXE_PATH" "$PYXVCS_PYTHON_ROOT/pyxvcs/cmdop.xsh" "$@"
  tkl_set_error $?

  exit $tkl__last_error
}

if [[ -z "$BASH_LINENO" || BASH_LINENO[0] -eq 0 ]]; then
  # Script was not included, then execute it.
  pyxvcs_cmdop "$@"
fi
