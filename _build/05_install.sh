#!/bin/bash

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
CMAKE_BUILD_TARGET="$2"

if [[ -z "$CMAKE_BUILD_TYPE" ]]; then
  echo "$0: error: CMAKE_BUILD_TYPE must be defined." >&2
  tkl_exit 255
fi

# CAUTION:
#   This declares only most probable variant (guess) respective to the script extension.
#   If not then the user have to explicitly pass the target name.
#
[[ -z "$CMAKE_BUILD_TARGET" ]] && CMAKE_BUILD_TARGET="install"

UpdateOsName

# preload configuration files only to make some checks
tkl_call set_vars_from_files \
  "${CONFIG_VARS_SYSTEM_FILE//;/\\;}" "$OS_NAME" . . . ";" \
  --exclude_vars_filter "PROJECT_ROOT" \
  --ignore_late_expansion_statements || tkl_exit $?

# check if selected generator is a multiconfig generator
tkl_call get_GENERATOR_IS_MULTI_CONFIG "$CMAKE_GENERATOR" || tkl_exit $?

if [[ "$CMAKE_BUILD_TYPE" == "*" ]]; then
  IFS=$'; \t\r\n'; for CMAKE_BUILD_TYPE in $CMAKE_CONFIG_TYPES; do
    Install "${@:3}" || tkl_exit $?
  done
else
  Install "${@:3}" || tkl_exit $?
fi

tkl_exit

fi
