#!/bin/bash

# Script can be ONLY included by "source" command.
if [[ -n "$BASH" && (-z "$BASH_LINENO" || BASH_LINENO[0] -gt 0) && "$TACKLELIB_SCRIPTS_INIT0_DIR" != "$BASH_SOURCE_DIR" ]]; then 

source '/bin/bash_entry' || exit $?

function __init0__()
{
  tkl_include '__init__.sh' || tkl_abort_include

  tkl_declare_global TACKLELIB_SCRIPTS_INIT0_DIR "$BASH_SOURCE_DIR" # including guard

  [[ -z "$NEST_LVL" ]] && NEST_LVL=0

  local i
  for i in PROJECT_ROOT \
    PROJECT_CACHE_ROOT PROJECT_LOG_ROOT PROJECT_CONFIG_ROOT PROJECT_SCRIPTS_ROOT PROJECT_SCRIPTS_TOOLS_ROOT TACKLELIB_PROJECT_EXTERNALS_ROOT PROJECT_CMAKE_ROOT \
    PROJECT_OUTPUT_ROOT PROJECT_OUTPUT_CONFIG_ROOT PROJECT_OUTPUT_CMAKE_ROOT \
    CONTOOLS_ROOT \
    TACKLELIB_BASH_SCRIPTS_ROOT TACKLELIB_PYTHON_SCRIPTS_ROOT \
    CMDOPLIB_PYTHON_SCRIPTS_ROOT \
    CONFIG_VARS_SYSTEM_FILE_IN CONFIG_VARS_SYSTEM_FILE CONFIG_VARS_USER_FILE_IN CONFIG_VARS_USER_FILE; do
    if [[ -z "$i" ]]; then
      echo "${FUNCNAME[0]}: error: \'$i\` variable is not defined." >&2
      tkl_abort_include
    fi
  done

  tkl_include "$PROJECT_SCRIPTS_TOOLS_ROOT/projectlib.sh" || tkl_abort_include
}

__init0__

fi
