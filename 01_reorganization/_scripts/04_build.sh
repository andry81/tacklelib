#!/bin/bash

# Script ONLY for execution.
if [[ -n "$BASH" && (-z "$BASH_LINENO" || BASH_LINENO[0] -eq 0) ]]; then

source '/bin/bash_entry' || exit $?
tkl_include '__init__/__init0__.sh' || tkl_abort_include

# no local logging if nested call
(( ! IMPL_MODE && ! NEST_LVL )) && {
  export IMPL_MODE=1
  exec 3>&1 4>&2
  tkl_push_trap 'exec 2>&4 1>&3' EXIT

  [[ ! -e "${SCRIPTS_LOGS_ROOT}/.log" ]] && mkdir "${SCRIPTS_LOGS_ROOT}/.log"

  # date time request base on: https://stackoverflow.com/questions/1401482/yyyy-mm-dd-format-date-in-shell-script/1401495#1401495
  #

  # RANDOM instead of milliseconds
  case $BASH_VERSION in
    # < 4.2
    [123].* | 4.[01] | 4.0* | 4.1[^0-9]*)
      LOG_FILE_NAME_SUFFIX=$(date "+%Y'%m'%d_%H'%M'%S''")$(( RANDOM % 1000 ))
      ;;
    # >= 4.2
    *)
      printf -v LOG_FILE_NAME_SUFFIX "%(%Y'%m'%d_%H'%M'%S'')T$(( RANDOM % 1000 ))" -1
      ;;
  esac

  # stdout+stderr redirection into the same log file with handles restore
  {
  {
  {
    exec $0 "$@" 2>&1 1>&8
  } | tee -a "${SCRIPTS_LOGS_ROOT}/.log/${LOG_FILE_NAME_SUFFIX}.${BASH_SOURCE_FILE_NAME%[.]*}.log" 1>&9
  } 8>&1 | tee -a "${SCRIPTS_LOGS_ROOT}/.log/${LOG_FILE_NAME_SUFFIX}.${BASH_SOURCE_FILE_NAME%[.]*}.log"
  } 9>&2

  exit $?
}

tkl_include "__init__/__init1__.sh" || exit $?

(( NEST_LVL++ ))

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
#   1. This declares only most probable variant (guess) respective to the script extension.
#      If not then the user have to explicitly pass the target name.
#   2. Sometimes throws a cmake error: `No rule to make target 'foo.dir/all', needed by 'boo.dir/all'`
#      Solution #1:
#         Use a correct relative path in the `add_subdirectory` function in the `binary_dir` parameter.
#
[[ -z "$CMAKE_BUILD_TARGET" ]] && CMAKE_BUILD_TARGET="all"

UpdateOsName

# preload configuration files only to make some checks
tkl_call set_vars_from_files \
  "${CONFIG_VARS_SYSTEM_FILE//;/\\;}" "$OS_NAME" . . . ";" \
  --exclude_vars_filter "PROJECT_ROOT" \
  --ignore_late_expansion_statements || tkl_exit

# check if selected generator is a multiconfig generator
tkl_call get_GENERATOR_IS_MULTI_CONFIG "$CMAKE_GENERATOR" || tkl_exit

if [[ "$CMAKE_BUILD_TYPE" == "*" ]]; then
  IFS=$'; \t\r\n'; for CMAKE_BUILD_TYPE in $CMAKE_CONFIG_TYPES; do
    Build "${@:3}" || tkl_exit
  done
else
  Build "${@:3}" || tkl_exit
fi

tkl_exit

fi
