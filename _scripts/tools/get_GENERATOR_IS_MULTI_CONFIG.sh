#!/bin/bash

# Another variant of a configuration file variables read and set script.
# The script must stay as simple as possible, so for this task it uses these parameters:
# 1. path where to lock a lock file
# 2. path where to read a file with variable names (each per line)
# 3. path where to read a file with variable values (each per line, must be the same quantity of lines with the variable names file)

# Script can be ONLY included by "source" command.
if [[ -n "$BASH" && (-z "$BASH_LINENO" || BASH_LINENO[0] -gt 0) ]]; then

source "/bin/bash_entry" || return $?
tkl_include "buildlib.sh" || return $?
tkl_include "set_vars_from_locked_file_pair.sh" || return $?

function get_GENERATOR_IS_MULTI_CONFIG()
{
  # drop return variable
  GENERATOR_IS_MULTI_CONFIG=""

  local CMAKE_GENERATOR="$1"

  if [[ -z "$CMAKE_GENERATOR" ]]; then
    echo "$0: error: CMAKE_GENERATOR is not defined." >&2
    return 126
  fi

  if [[ -z "$PROJECT_ROOT" ]]; then
    echo "$0: error: PROJECT_ROOT is not defined." >&2
    return 127
  fi

  local TEMP_OUTPUT_DIR=`mktemp -d -t get_GENERATOR_IS_MULTI_CONFIG.XXXXXXXXXX`

  if [[ ! -d "$TEMP_OUTPUT_DIR" ]]; then
    echo "$0: error: could not create temporary directory: \`$TEMP_OUTPUT_DIR\`"
    return 255
  fi

  # cleanup on return
  tkl_push_trap "rm -rf \"$TEMP_OUTPUT_DIR\" 2> /dev/null" RETURN

  local RETURN_VALUE
  tkl_convert_backend_path_to_native "$TEMP_OUTPUT_DIR" s
  TEMP_OUTPUT_DIR="$RETURN_VALUE"

  # arguments: <out_file_file>
  tkl_call_and_print_if "(( TOOLS_VERBOSE ))" cmake -G "$CMAKE_GENERATOR" "-DCMAKE_MODULE_PATH=$PROJECT_ROOT/cmake" \
  -P "$PROJECT_ROOT/cmake/tacklelib/tools/GeneratorIsMulticonfig.cmd.cmake" \
  --flock "$TEMP_OUTPUT_DIR/lock" "$TEMP_OUTPUT_DIR/var_values.lst" || return $?

  echo "GENERATOR_IS_MULTI_CONFIG" > "$TEMP_OUTPUT_DIR/var_names.lst" || return $?

  tkl_call_and_print_if "(( TOOLS_VERBOSE ))" set_vars_from_locked_file_pair \
    "$TEMP_OUTPUT_DIR/lock" "$TEMP_OUTPUT_DIR/var_names.lst" "$TEMP_OUTPUT_DIR/var_values.lst" \
    "$PRINT_VARS_SET" || return $?

  return 0
}

fi
