#!/bin/bash

# Script can be ONLY included by "source" command.
[[ -z "$BASH" || (-n "$BASH_LINENO" && BASH_LINENO[0] -le 0) || (-n "$TACKLELIB_PROJECT_ROOT_INIT0_DIR" && "$TACKLELIB_PROJECT_ROOT_INIT0_DIR" == "$BASH_SOURCE_DIR") ]] && return

source '/bin/bash_tacklelib' || exit $?

[[ BASH_SOURCE_NEST_LVL -eq 0 ]] && tkl_make_source_file_components

[[ -z "$NEST_LVL" ]] && tkl_declare_global NEST_LVL 0

[[ -z "$TACKLELIB_PROJECT_ROOT" ]] && \
{
  tkl_normalize_path "$BASH_SOURCE_DIR/.." -a || tkl_abort 9
  tkl_export TACKLELIB_PROJECT_ROOT                 "${RETURN_VALUE:-*:\$\{TACKLELIB_PROJECT_ROOT\}}" # safety: replace by not applicable or unexisted directory if empty
}
[[ -z "$TACKLELIB_PROJECT_EXTERNALS_ROOT" ]] &&     tkl_export TACKLELIB_PROJECT_EXTERNALS_ROOT     "$TACKLELIB_PROJECT_ROOT/_externals"

[[ -z "$TACKLELIB_PROJECT_OUTPUT_ROOT" ]] &&        tkl_export TACKLELIB_PROJECT_OUTPUT_ROOT        "$TACKLELIB_PROJECT_ROOT/_out"

[[ -z "$PROJECT_OUTPUT_ROOT" ]] &&                  tkl_export PROJECT_OUTPUT_ROOT                  "$TACKLELIB_PROJECT_OUTPUT_ROOT"

[[ -z "$TACKLELIB_PROJECT_BUILD_ROOT" ]] &&         tkl_export TACKLELIB_PROJECT_BUILD_ROOT         "$TACKLELIB_PROJECT_ROOT/_build"

[[ -z "$TACKLELIB_PROJECT_INPUT_CONFIG_ROOT" ]] &&  tkl_export TACKLELIB_PROJECT_INPUT_CONFIG_ROOT  "$TACKLELIB_PROJECT_ROOT/_config"
[[ -z "$TACKLELIB_PROJECT_OUTPUT_CONFIG_ROOT" ]] && tkl_export TACKLELIB_PROJECT_OUTPUT_CONFIG_ROOT "$PROJECT_OUTPUT_ROOT/config/tacklelib"

[[ -z "$TACKLELIB_BASH_ROOT" ]] &&                  tkl_export TACKLELIB_BASH_ROOT                  "$TACKLELIB_PROJECT_ROOT/bash/tacklelib"
[[ -z "$TACKLELIB_CMAKE_ROOT" ]] &&                 tkl_export TACKLELIB_CMAKE_ROOT                 "$TACKLELIB_PROJECT_ROOT/cmake/tacklelib"
[[ -z "$TACKLELIB_PYTHON_ROOT" ]] &&                tkl_export TACKLELIB_PYTHON_ROOT                "$TACKLELIB_PROJECT_ROOT/python/tacklelib"
[[ -z "$TACKLELIB_VBS_ROOT" ]] &&                   tkl_export TACKLELIB_VBS_ROOT                   "$TACKLELIB_PROJECT_ROOT/vbs/tacklelib"

[[ -z "$CMDOPLIB_PYTHON_ROOT" ]] &&                 tkl_export CMDOPLIB_PYTHON_ROOT                 "$TACKLELIB_PROJECT_ROOT/python/cmdoplib"

[[ -z "$PYXVCS_PYTHON_ROOT" ]] &&                   tkl_export PYXVCS_PYTHON_ROOT                   "$TACKLELIB_PROJECT_ROOT/python/pyxvcs"

# init external projects

if [[ -f "$TACKLELIB_PROJECT_EXTERNALS_ROOT/contools/__init__/__init__.sh" ]]; then
  tkl_include "$TACKLELIB_PROJECT_EXTERNALS_ROOT/contools/__init__/__init__.sh" || tkl_abort_include
fi

tkl_include "$TACKLELIB_PROJECT_BUILD_ROOT/tools/projectlib.sh" || tkl_abort_include

[[ ! -e "$PROJECT_OUTPUT_ROOT" ]] && { mkdir -p "$PROJECT_OUTPUT_ROOT" || tkl_abort 10 }
[[ ! -e "$TACKLEBAR_PROJECT_OUTPUT_CONFIG_ROOT" ]] && { mkdir -p "$TACKLEBAR_PROJECT_OUTPUT_CONFIG_ROOT" || tkl_abort 11 }

tkl_call_inproc_entry load_config "$TACKLELIB_BASH_ROOT/tools/load_config.sh" "$TACKLELIB_PROJECT_INPUT_CONFIG_ROOT" "$TACKLELIB_PROJECT_OUTPUT_CONFIG_ROOT" "config.system.vars" || \
{
  echo "$BASH_SOURCE_FILE_NAME: error: \`$TACKLELIB_PROJECT_OUTPUT_CONFIG_ROOT/config.system.vars\` is not loaded."
  tkl_abort 255
} >&2

for (( i=0; ; i++ )); do
  [[ ! -e "$TACKLELIB_PROJECT_INPUT_CONFIG_ROOT/config.$i.vars.in" ]] && break

  tkl_call_inproc_entry load_config "$TACKLELIB_BASH_ROOT/tools/load_config.sh" "$TACKLELIB_PROJECT_INPUT_CONFIG_ROOT" "$TACKLELIB_PROJECT_OUTPUT_CONFIG_ROOT" "config.$i.vars" || \
  {
    echo "$BASH_SOURCE_FILE_NAME: error: \`$TACKLELIB_PROJECT_OUTPUT_CONFIG_ROOT/config.$i.vars\` is not loaded."
    tkl_abort 255
  } >&2
done

TACKLELIB_PROJECT_ROOT_INIT0_DIR="$BASH_SOURCE_DIR" # including guard

: # resets exit code to 0
