#!/bin/bash

# Configuration variable files generator script.

# Script ONLY for execution.
if [[ -n "$BASH" && (-z "$BASH_LINENO" || BASH_LINENO[0] -eq 0) ]]; then 

source "/bin/bash_entry" || exit $?
tkl_include "__init__/__init0__.sh" || exit $?

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

  (
  (
    exec $0 "$@"
  ) | tee -a "${SCRIPTS_LOGS_ROOT}/.log/${LOG_FILE_NAME_SUFFIX}.${BASH_SOURCE_FILE_NAME%[.]*}.log" 2>&1
  ) 1>&3 2>&4

  exit $?
}

IN_GENERATOR_SCRIPT=1

tkl_include "__init__/__init1__.sh" || exit $?

(( NEST_LVL+=1 ))


GenerateConfig || tkl_exit $?

tkl_exit

fi
