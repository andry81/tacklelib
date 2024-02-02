#!/bin/bash

# Configurator for cmake with generator.

# Script ONLY for execution.
[[ -n "$BASH" && (-z "$BASH_LINENO" || BASH_LINENO[0] -eq 0) ]] || return 0 || exit 0 # exit to avoid continue if the return can not be called

if [[ -z "$SOURCE_TACKLELIB_BASH_TACKLELIB_SH" || SOURCE_TACKLELIB_BASH_TACKLELIB_SH -eq 0 ]]; then
  # builtin search
  for BASH_SOURCE_DIR in "/usr/local/bin" "/usr/bin" "/bin"; do
    if [[ -f "$BASH_SOURCE_DIR/bash_tacklelib" ]]; then
      source "$BASH_SOURCE_DIR/bash_tacklelib" || exit $?
      break
    fi
  done
fi

tkl_include_or_abort '__init__/__init__.sh'

# workaround for the bug in the "[@]:i" expression under the bash version lower than 4.1
IFS=$' \t\r\n' \
  tkl_make_command_line '' 1 "$@"
echo -e ">$RETURN_VALUE\n"

tkl_exec_project_logging

tkl_call_and_print_if "(( INIT_VERBOSE ))" CheckConfigVersion 0 \
  "$CMAKE_CONFIG_VARS_SYSTEM_FILE_IN" "$CMAKE_CONFIG_VARS_SYSTEM_FILE" \
  "$CMAKE_CONFIG_VARS_USER_0_FILE_IN" "$CMAKE_CONFIG_VARS_USER_0_FILE" || tkl_abort $?

tkl_include_or_abort "$TACKLELIB_BASH_ROOT/tacklelib/tools/cmake/set_vars_from_files.sh"
tkl_include_or_abort "$TACKLELIB_BASH_ROOT/tacklelib/tools/cmake/get_GENERATOR_IS_MULTI_CONFIG.sh"

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
  "${CMAKE_CONFIG_VARS_SYSTEM_FILE//;/\\;}" "$OS_NAME" . . . ";" \
  --exclude_vars_filter "TACKLELIB_PROJECT_ROOT" \
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
