#!/bin/bash

# Configurator for cmake with generator.

# Script ONLY for execution.
if [[ -n "$BASH" && (-z "$BASH_LINENO" || BASH_LINENO[0] -eq 0) ]]; then

source '/bin/bash_tacklelib' || exit $?
tkl_include '__init__/__init__.sh' || tkl_abort_include

tkl_exec_project_logging

tkl_call_and_print_if "(( INIT_VERBOSE ))" CheckConfigVersion 0 \
  "$CONFIG_VARS_SYSTEM_FILE_IN" "$CONFIG_VARS_SYSTEM_FILE" \
  "$CONFIG_VARS_USER_FILE_IN" "$CONFIG_VARS_USER_FILE" || tkl_abort $?

tkl_include "tools/set_vars_from_files.sh" || tkl_abort_include
tkl_include "tools/get_GENERATOR_IS_MULTI_CONFIG.sh" || tkl_abort_include

# CAUTION: an empty value and `*` value has different meanings!
#
CMAKE_BUILD_TYPE="$1"
CMAKE_BUILD_TYPE_WITH_FORCE=0

CMAKE_IS_SINGLE_CONFIG=0

if [[ -n "$CMAKE_BUILD_TYPE" && "${CMAKE_BUILD_TYPE//!/}" != "$CMAKE_BUILD_TYPE" ]]; then
  CMAKE_BUILD_TYPE="${CMAKE_BUILD_TYPE//!/}"
  CMAKE_BUILD_TYPE_WITH_FORCE=1
  CMAKE_IS_SINGLE_CONFIG=1
fi

UpdateOsName

# preload configuration files only to make some checks
tkl_call set_vars_from_files \
  "${CONFIG_VARS_SYSTEM_FILE//;/\\;}" "$OS_NAME" . . . ";" \
  --exclude_vars_filter "PROJECT_ROOT" \
  --ignore_late_expansion_statements || tkl_exit $?

# check if selected generator is a multiconfig generator
tkl_call get_GENERATOR_IS_MULTI_CONFIG "$CMAKE_GENERATOR" || tkl_exit $?

if (( GENERATOR_IS_MULTI_CONFIG )); then
  # CMAKE_CONFIG_TYPES must not be defined
  if [[ CMAKE_BUILD_TYPE_WITH_FORCE -eq 0 && -n "$CMAKE_BUILD_TYPE" ]]; then
    echo "$0: error: declared cmake generator is a multiconfig generator, CMAKE_BUILD_TYPE must not be defined: CMAKE_GENERATOR=\`$CMAKE_GENERATOR\` CMAKE_BUILD_TYPE=\`$CMAKE_BUILD_TYPE\`." >&2
    tkl_exit 127
  fi
else
  # CMAKE_CONFIG_TYPES must be defined
  if [[ -z "$CMAKE_BUILD_TYPE" ]]; then
    echo "$0: error: declared cmake generator is not a multiconfig generator, CMAKE_BUILD_TYPE must be defined: CMAKE_GENERATOR=\`$CMAKE_GENERATOR\` CMAKE_BUILD_TYPE=\`$CMAKE_BUILD_TYPE\`." >&2
    tkl_exit 128
  fi
  CMAKE_IS_SINGLE_CONFIG=1
fi

if [[ "$CMAKE_BUILD_TYPE" == "*" ]]; then
  IFS=$'; \t\r\n'; for CMAKE_BUILD_TYPE in $CMAKE_CONFIG_TYPES; do
    Configure "${@:2}" || tkl_exit $?
  done
else
  Configure "${@:2}" || tkl_exit $?
fi

tkl_exit

fi
