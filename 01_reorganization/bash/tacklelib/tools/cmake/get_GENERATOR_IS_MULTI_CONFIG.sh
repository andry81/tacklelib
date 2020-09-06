#!/bin/bash

# Script can be ONLY included by "source" command.
if [[ -n "$BASH" && (-z "$BASH_LINENO" || BASH_LINENO[0] -gt 0) ]]; then

source '/bin/bash_entry' || exit $?

function get_GENERATOR_IS_MULTI_CONFIG()
{
  # drop return variable
  GENERATOR_IS_MULTI_CONFIG=""

  local CMAKE_GENERATOR="$1"

  local i
  for i in CMAKE_GENERATOR PROJECT_ROOT PROJECT_CMAKE_ROOT TACKLELIB_BASH_SCRIPTS_ROOT TACKLELIB_CMAKE_SCRIPTS_ROOT; do
    if [[ -z "$i" ]]; then
      echo "${FUNCNAME[0]}: error: \'$i\` variable is not defined." >&2
      exit 255
    fi
  done

  tkl_include "$TACKLELIB_BASH_SCRIPTS_ROOT/buildlib.sh" || exit $?
  tkl_include "$TACKLELIB_BASH_SCRIPTS_ROOT/tools/set_vars_from_locked_file_pair.sh" || exit $?

  local TEMP_OUTPUT_DIR=`mktemp -d -t get_GENERATOR_IS_MULTI_CONFIG.XXXXXXXXXX`

  if [[ ! -d "$TEMP_OUTPUT_DIR" ]]; then
    echo "$0: error: could not create temporary directory: \`$TEMP_OUTPUT_DIR\`"
    return 255
  fi

  # cleanup on return
  tkl_push_trap "rm -rf \"$TEMP_OUTPUT_DIR\" 2> /dev/null" RELEASE

  local RETURN_VALUE
  tkl_convert_backend_path_to_native "$TEMP_OUTPUT_DIR" s
  TEMP_OUTPUT_DIR="$RETURN_VALUE"

  # arguments: <out_file_file>
  tkl_call_and_print_if "(( TOOLS_VERBOSE ))" cmake -G "$CMAKE_GENERATOR" "-DCMAKE_MODULE_PATH=$PROJECT_CMAKE_ROOT" \
  -P "$TACKLELIB_CMAKE_SCRIPTS_ROOT/tools/GeneratorIsMulticonfig.cmd.cmake" \
  --flock "$TEMP_OUTPUT_DIR/lock" "$TEMP_OUTPUT_DIR/var_values.lst" || return $?

  echo "GENERATOR_IS_MULTI_CONFIG" > "$TEMP_OUTPUT_DIR/var_names.lst" || return $?

  tkl_call_and_print_if "(( TOOLS_VERBOSE ))" set_vars_from_locked_file_pair \
    "$TEMP_OUTPUT_DIR/lock" "$TEMP_OUTPUT_DIR/var_names.lst" "$TEMP_OUTPUT_DIR/var_values.lst" \
    "$PRINT_VARS_SET" || return $?

  return 0
}

fi
