#!/bin/bash

# Script can be ONLY included by "source" command.
[[ -n "$BASH" && (-z "$BASH_LINENO" || BASH_LINENO[0] -gt 0) ]] || return 0 || exit 0 # exit to avoid continue if the return can not be called

if [[ -z "$SOURCE_TACKLELIB_BASH_TACKLELIB_SH" || SOURCE_TACKLELIB_BASH_TACKLELIB_SH -eq 0 ]]; then
  # builtin search
  for BASH_SOURCE_DIR in "/usr/local/bin" "/usr/bin" "/bin"; do
    if [[ -f "$BASH_SOURCE_DIR/bash_tacklelib" ]]; then
      source "$BASH_SOURCE_DIR/bash_tacklelib" || exit $?
      break
    fi
  done
fi

tkl_include_or_abort "$TACKLELIB_BASH_ROOT/tacklelib/buildlib.sh"
tkl_include_or_abort "$TACKLELIB_BASH_ROOT/tacklelib/tools/set_vars_from_locked_file_pair.sh"

function get_GENERATOR_IS_MULTI_CONFIG()
{
  # drop return variable
  GENERATOR_IS_MULTI_CONFIG=""

  local CMAKE_GENERATOR="$1"

  local i
  for i in CMAKE_GENERATOR TACKLELIB_CMAKE_ROOT; do
    if [[ -z "$i" ]]; then
      echo "${FUNCNAME[0]}: error: \'$i\` variable is not defined." >&2
      exit 255
    fi
  done

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
  tkl_call_and_print_if "(( TOOLS_VERBOSE ))" cmake -G "$CMAKE_GENERATOR" "-DCMAKE_MODULE_PATH=$TACKLELIB_CMAKE_ROOT" \
  -P "$TACKLELIB_CMAKE_ROOT/tacklelib/tools/GeneratorIsMulticonfig.cmd.cmake" \
  --flock "$TEMP_OUTPUT_DIR/lock" "$TEMP_OUTPUT_DIR/var_values.lst" || return $?

  echo "GENERATOR_IS_MULTI_CONFIG" > "$TEMP_OUTPUT_DIR/var_names.lst" || return $?

  tkl_call_and_print_if "(( TOOLS_VERBOSE ))" tkl_set_vars_from_locked_file_pair \
    "$TEMP_OUTPUT_DIR/lock" "$TEMP_OUTPUT_DIR/var_names.lst" "$TEMP_OUTPUT_DIR/var_values.lst" \
    "$PRINT_VARS_SET" || return $?

  return 0
}
