#!/bin/bash

# Script can be ONLY included by "source" command.
if [[ -n "$BASH" && (-z "$BASH_LINENO" || BASH_LINENO[0] -gt 0) && "$TACKLELIB_CMAKE_TESTS_SCRIPTS_INIT0_DIR" != "$BASH_SOURCE_DIR" ]]; then 

source '/bin/bash_entry' || exit $?
tkl_include "../../../__init__/__init__.sh" || tkl_abort_include

TACKLELIB_CMAKE_TESTS_SCRIPTS_INIT0_DIR="$BASH_SOURCE_DIR" # including guard

function __init0__()
{
  # CAUTION:
  #   Here is declared ONLY a basic set of system variables required immediately in this file.
  #   All the rest system variables will be loaded from the `config.*.vars` files.
  #

  local MUST_LOAD_CONFIG=${1:-1}

  [[ -z "$NEST_LVL" ]] && tkl_declare_global NEST_LVL 0

  # basic set of system variables
  tkl_export PROJECT_CMAKE_TESTS_ROOT                 "$PROJECT_ROOT/cmake_tests"

  tkl_export PROJECT_CMAKE_TESTS_CONFIG_ROOT          "$PROJECT_CMAKE_TESTS_ROOT/_config"

  tkl_export PROJECT_OUTPUT_CMAKE_TESTS_CONFIG_ROOT   "$PROJECT_OUTPUT_CONFIG_ROOT/cmake_tests"

  tkl_set_error 0

  local IFS=$' \t\n'

  if [[ -e "$PROJECT_CMAKE_TESTS_CONFIG_ROOT/config.system.vars.in" && -e "$PROJECT_OUTPUT_CMAKE_TESTS_CONFIG_ROOT/config.system.vars" ]]; then
    tkl_call_inproc_entry load_config "$TACKLELIB_BASH_SCRIPTS_ROOT/tools/load_config.sh" "$PROJECT_CMAKE_TESTS_CONFIG_ROOT" "$PROJECT_OUTPUT_CMAKE_TESTS_CONFIG_ROOT" "config.system.vars"
  else
    (( 0 )) # raise error level
  fi

  (( $? && MUST_LOAD_CONFIG != 0 )) && {
    echo "$BASH_SOURCE_FILE_NAME: error: \`$PROJECT_OUTPUT_CMAKE_TESTS_CONFIG_ROOT/config.system.vars\` is not loaded." >&2
    tkl_abort 255
  }

  local i

  for (( i=0; ; i++ )); do
    if [[ -e "$PROJECT_CMAKE_TESTS_CONFIG_ROOT/config.$i.vars.in" && -e "$PROJECT_OUTPUT_CMAKE_TESTS_CONFIG_ROOT/config.$i.vars" ]]; then
      tkl_call_inproc_entry load_config "$TACKLELIB_BASH_SCRIPTS_ROOT/tools/load_config.sh" "$PROJECT_CMAKE_TESTS_CONFIG_ROOT" "$PROJECT_OUTPUT_CMAKE_TESTS_CONFIG_ROOT" "config.$i.vars"
    else
      (( 0 )) # raise error level
    fi

    (( $? && MUST_LOAD_CONFIG != 0 )) && {
      echo "$BASH_SOURCE_FILE_NAME: error: \`$PROJECT_OUTPUT_CMAKE_TESTS_CONFIG_ROOT/config.$i.vars\` is not loaded." >&2
      tkl_abort 255
    }

    [[ ! -e "$PROJECT_OUTPUT_CMAKE_TESTS_CONFIG_ROOT/config.$i.vars" ]] && break
  done

  tkl_include "$PROJECT_CMAKE_TESTS_SCRIPTS_TOOLS_ROOT/projectlib.sh" || tkl_abort_include
}

__init0__

fi
