#!/bin/bash

# Another variant of a configuration file variables read and set script.
# The script must stay as simple as possible, so for this task it uses these parameters:
# 1. path where to lock a lock file
# 2. path where to read a file with variable names (each per line)
# 3. path where to read a file with variable values (each per line, must be the same quantity of lines with the variable names file)

# Script can be ONLY included by "source" command.
if [[ -n "$BASH" && (-z "$BASH_LINENO" || BASH_LINENO[0] -gt 0) ]]; then

source '/bin/bash_entry' || exit $?

function tkl_set_vars_from_files()
{
  local i
  for i in PROJECT_ROOT PROJECT_CMAKE_ROOT TACKLELIB_BASH_SCRIPTS_ROOT TACKLELIB_CMAKE_SCRIPTS_ROOT; do
    if [[ -z "$i" ]]; then
      echo "${FUNCNAME[0]}: error: \'$i\` variable is not defined." >&2
      exit 255
    fi
  done

  if [[ -z ${PROJECT_ROOT+x} ]]; then
    echo "$0: error: PROJECT_ROOT is not defined." >&2
    return 127
  fi

  tkl_include "$TACKLELIB_BASH_SCRIPTS_ROOT/buildlib.sh" || exit $?
  tkl_include "$TACKLELIB_BASH_SCRIPTS_ROOT/tools/set_vars_from_locked_file_pair.sh" || exit $?

  local TEMP_OUTPUT_DIR=`mktemp -d -t set_vars_from_files.XXXXXXXXXX`

  if [[ ! -d "$TEMP_OUTPUT_DIR" ]]; then
    echo "$0: error: could not create temporary directory: \`$TEMP_OUTPUT_DIR\`"
    return 255
  fi

  # cleanup on return
  tkl_push_trap "rm -rf \"$TEMP_OUTPUT_DIR\" 2> /dev/null" RELEASE

  local RETURN_VALUE
  tkl_convert_backend_path_to_native "$TEMP_OUTPUT_DIR" s
  TEMP_OUTPUT_DIR="$RETURN_VALUE"

  # arguments: <flag0>[...<flagN>] "<file0>[...\;<fileN>]" <os_name> <compiler_name> <config_name> <arch_name> <list_separator_char>
  tkl_call_and_print_if "(( TOOLS_VERBOSE ))" cmake "-DCMAKE_MODULE_PATH=$PROJECT_CMAKE_ROOT" \
    -P "$TACKLELIB_CMAKE_SCRIPTS_ROOT/tools/SetVarsFromFiles.cmd.cmake" \
    "${@:7}" \
    --flock "$TEMP_OUTPUT_DIR/lock" --vars "$TEMP_OUTPUT_DIR/var_names.lst" --values "$TEMP_OUTPUT_DIR/var_values.lst" \
    "${@:1:6}" || return $?

  tkl_call_and_print_if "(( TOOLS_VERBOSE ))" set_vars_from_locked_file_pair \
    "$TEMP_OUTPUT_DIR/lock" "$TEMP_OUTPUT_DIR/var_names.lst" "$TEMP_OUTPUT_DIR/var_values.lst" \
    "$PRINT_VARS_SET" || return $?

  return 0
}

fi
