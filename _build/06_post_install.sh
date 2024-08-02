#!/bin/bash

# Script ONLY for execution.
[[ -n "$BASH" && (-z "$BASH_LINENO" || BASH_LINENO[0] -eq 0) ]] || return 0 || exit 0 # exit to avoid continue if the return can not be called

if [[ -z "$SOURCE_TACKLELIB_BASH_TACKLELIB_SH" || SOURCE_TACKLELIB_BASH_TACKLELIB_SH -eq 0 ]]; then
  # builtin search
  for BASH_SOURCE_DIR in '/usr/local/bin' '/usr/bin' '/bin'; do
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
CMAKE_BUILD_TARGET="*"  # CMAKE_BUILD_TARGET="$2" # post install use target `all` to make postinstall

if [[ -z "$CMAKE_BUILD_TYPE" ]]; then
  echo "$0: error: CMAKE_BUILD_TYPE must be defined." >&2
  tkl_exit 255
fi

UpdateOsName

# preload configuration files only to make some checks
tkl_call set_vars_from_files \
  "${CMAKE_CONFIG_VARS_SYSTEM_FILE//;/\\;}" "$OS_NAME" . . . ";" \
  --exclude_vars_filter "TACKLELIB_PROJECT_ROOT" \
  --ignore_late_expansion_statements || tkl_exit $?

# check if selected generator is a multiconfig generator
tkl_call get_GENERATOR_IS_MULTI_CONFIG "$CMAKE_GENERATOR" || tkl_exit $?

FILE_DEPS_ROOT_LIST="*.so:*.so.*:*.a:*.a.*"
FILE_DEPS_LIST_TO_FIND=".:./plugins/platforms"
FILE_DEPS_LIST_TO_EXCLUDE="linux-gate.so.1"
FILE_DEPS_LD_PATH_LIST=".:./plugins/platforms:$QT5_ROOT/lib"
FILE_DEPS_MKDIR_LIST="_build:_build/admin:_build/deploy:lib:plugins:plugins/platforms"
FILE_DEPS_CPDIR_LIST="$QT5_ROOT/plugins/platforms/.:./plugins/platforms"

if [[ "$CMAKE_BUILD_TYPE" == "*" ]]; then
  IFS=$'; \t\r\n'; for CMAKE_BUILD_TYPE in $CMAKE_CONFIG_TYPES; do
    PostInstall || tkl_exit $?
  done
else
  PostInstall || tkl_exit $?
fi

tkl_exit
