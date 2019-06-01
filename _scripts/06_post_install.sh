#!/bin/bash

# Script ONLY for execution.
if [[ -n "$BASH" && (-z "$BASH_LINENO" || ${BASH_LINENO[0]} -eq 0) ]]; then 

source "/bin/bash_entry" || exit $?
tkl_include "__init1__.sh" || exit $?

(( NEST_LVL++ ))

source "$PROJECT_ROOT/_scripts/tools/set_vars_from_files.sh" || Exit
source "$PROJECT_ROOT/_scripts/tools/get_GENERATOR_IS_MULTI_CONFIG.sh" || Exit


# CAUTION: an empty value and `*` value has different meanings!
#
CMAKE_BUILD_TYPE="$1"
CMAKE_BUILD_TARGET="*"  # CMAKE_BUILD_TARGET="$2" # post install use target `all` to make postinstall

if [[ -z "$CMAKE_BUILD_TYPE" ]]; then
  echo "$0: error: CMAKE_BUILD_TYPE must be defined." >&2
  Exit 255
fi

UpdateOsName

# preload configuration files only to make some checks
Call set_vars_from_files \
  "${CONFIG_VARS_SYSTEM_FILE//;/\\;}" "$OS_NAME" . . . ";" \
  --exclude_vars_filter "PROJECT_ROOT" \
  --ignore_late_expansion_statements || Exit

# check if selected generator is a multiconfig generator
Call get_GENERATOR_IS_MULTI_CONFIG "$CMAKE_GENERATOR" || Exit

FILE_DEPS_ROOT_LIST="*.so:*.so.*:*.a:*.a.*"
FILE_DEPS_LIST_TO_FIND=".:./plugins/platforms"
FILE_DEPS_LIST_TO_EXCLUDE="linux-gate.so.1"
FILE_DEPS_LD_PATH_LIST=".:./plugins/platforms:$QT5_ROOT/lib"
FILE_DEPS_MKDIR_LIST="_scripts:_scripts/admin:_scripts/deploy:lib:plugins:plugins/platforms"
FILE_DEPS_CPDIR_LIST="$QT5_ROOT/plugins/platforms/.:./plugins/platforms"

if [[ "$CMAKE_BUILD_TYPE" == "*" ]]; then
  IFS=$'; \t\r\n'; for CMAKE_BUILD_TYPE in $CMAKE_CONFIG_TYPES; do
    PostInstall || Exit
  done
else
  PostInstall || Exit
fi

Exit

fi
