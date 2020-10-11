#!/bin/bash

# Script can be ONLY included by "source" command.
if [[ -n "$BASH" && (-z "$BASH_LINENO" || BASH_LINENO[0] -gt 0) && "$TACKLELIB_SCRIPTS_INIT0_DIR" != "$BASH_SOURCE_DIR" ]]; then

source '/bin/bash_entry' || exit $?

TACKLELIB_SCRIPTS_INIT0_DIR="$BASH_SOURCE_DIR" # including guard

function __init__()
{
  # CAUTION:
  #   Here is declared ONLY a basic set of system variables required immediately in this file.
  #   All the rest system variables will be loaded from the `config.*.vars` files.
  #

  local MUST_LOAD_CONFIG=${1:-1}

  [[ -z "$NEST_LVL" ]] && tkl_declare_global NEST_LVL 0

  tkl_normalize_path "$BASH_SOURCE_DIR/.." -a || tkl_abort 10
  tkl_export TACKLELIB_PROJECT_ROOT                     "${RETURN_VALUE:-*:\$\{TACKLELIB_PROJECT_ROOT\}}" # safety: replace by not applicable or unexisted directory if empty

  tkl_export TACKLELIB_PROJECT_CONFIG_ROOT              "$TACKLELIB_PROJECT_ROOT/_config"

  [[ -z "$PROJECT_OUTPUT_ROOT" ]] && tkl_export PROJECT_OUTPUT_ROOT "$TACKLELIB_PROJECT_ROOT/_out"

  tkl_export TACKLELIB_PROJECT_OUTPUT_CONFIG_ROOT       "$TACKLELIB_PROJECT_OUTPUT_ROOT/config/tacklelib"

  tkl_export TACKLELIB_PROJECT_EXTERNALS_ROOT           "$TACKLELIB_PROJECT_ROOT/_externals"

  tkl_export CONTOOLS_ROOT                              "$TACKLELIB_PROJECT_EXTERNALS_ROOT/contools/Scripts/Tools"

  tkl_export TACKLELIB_BASH_SCRIPTS_ROOT                "$TACKLELIB_PROJECT_ROOT/bash/tacklelib"

  tkl_set_error 0

  local IFS=$' \t\n'

  [[ ! -e "$TACKLEBAR_PROJECT_OUTPUT_CONFIG_ROOT" ]] && { mkdir -p "$TACKLEBAR_PROJECT_OUTPUT_CONFIG_ROOT" || tkl_abort 11 }

  tkl_call_inproc_entry load_config "$TACKLELIB_BASH_SCRIPTS_ROOT/tools/load_config.sh" "$TACKLELIB_PROJECT_CONFIG_ROOT" "$TACKLELIB_PROJECT_OUTPUT_CONFIG_ROOT" "config.system.vars"

  (( $? && MUST_LOAD_CONFIG != 0 )) && {
    echo "$BASH_SOURCE_FILE_NAME: error: \`$TACKLELIB_PROJECT_OUTPUT_CONFIG_ROOT/config.system.vars\` is not loaded." >&2
    tkl_abort 255
  }

  local i
  for i in PROJECT_ROOT \
    PROJECT_CACHE_ROOT PROJECT_LOG_ROOT PROJECT_CONFIG_ROOT PROJECT_CONFIG_SCRIPTS_ROOT PROJECT_SCRIPTS_ROOT PROJECT_SCRIPTS_TOOLS_ROOT PROJECT_CMAKE_ROOT \
    PROJECT_OUTPUT_ROOT PROJECT_OUTPUT_CONFIG_ROOT PROJECT_OUTPUT_CMAKE_ROOT \
    CONTOOLS_ROOT \
    PROJECT_CMAKE_CONFIG_ROOT PROJECT_OUTPUT_CMAKE_CONFIG_ROOT \
    TACKLELIB_BASH_SCRIPTS_ROOT TACKLELIB_CMAKE_SCRIPTS_ROOT TACKLELIB_PYTHON_SCRIPTS_ROOT \
    CMDOPLIB_PYTHON_SCRIPTS_ROOT \
    PYXVCS_BASH_SCRIPTS_ROOT PYXVCS_PYTHON_SCRIPTS_ROOT PYXVCS_BATCH_SCRIPTS_ROOT; do
    if [[ -z "$i" ]]; then
      echo "${FUNCNAME[0]}: error: \'$i\` variable is not defined." >&2
      tkl_abort_include
    fi
  done

  for (( i=0; ; i++ )); do
    [[ ! -e "$TACKLELIB_PROJECT_CONFIG_ROOT/config.$i.vars.in" ]] && break

    tkl_call_inproc_entry load_config "$TACKLELIB_BASH_SCRIPTS_ROOT/tools/load_config.sh" "$TACKLELIB_PROJECT_CONFIG_ROOT" "$TACKLELIB_PROJECT_OUTPUT_CONFIG_ROOT" "config.$i.vars"

    (( $? && MUST_LOAD_CONFIG != 0 )) && {
      echo "$BASH_SOURCE_FILE_NAME: error: \`$TACKLELIB_PROJECT_OUTPUT_CONFIG_ROOT/config.$i.vars\` is not loaded." >&2
      tkl_abort 255
    }

  done

  tkl_include "$TACKLELIB_PROJECT_SCRIPTS_TOOLS_ROOT/projectlib.sh" || tkl_abort_include
}

__init__

fi
