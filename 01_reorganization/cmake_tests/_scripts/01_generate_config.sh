#!/bin/bash

# Configuration variable files generator script.

# Script ONLY for execution.
if [[ -n "$BASH" && (-z "$BASH_LINENO" || BASH_LINENO[0] -eq 0) ]]; then

source '/bin/bash_entry' || exit $?

function main()
{
  local i
  for i in PROJECT_ROOT PROJECT_LOG_ROOT PROJECT_CONFIG_ROOT PROJECT_SCRIPTS_ROOT; do
    if [[ -z "$i" ]]; then
      echo "${FUNCNAME[0]}: error: \'$i\` variable is not defined." >&2
      exit 255
    fi
  done

  tkl_include "$PROJECT_SCRIPTS_ROOT/__init__/__init0__.sh" || tkl_abort_include 

  # no local logging if nested call
  (( ! IMPL_MODE && ! NEST_LVL )) && {
    export IMPL_MODE=1
    exec 3>&1 4>&2
    tkl_push_trap 'exec 2>&4 1>&3' EXIT

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

    tkl_export PROJECT_LOG_DIR  "$PROJECT_LOG_ROOT/${LOG_FILE_NAME_SUFFIX}.${BASH_SOURCE_FILE_NAME%[.]*}"
    tkl_export PROJECT_LOG_FILE "$PROJECT_LOG_DIR/${LOG_FILE_NAME_SUFFIX}.${BASH_SOURCE_FILE_NAME%[.]*}.log"

    [[ ! -e "$PROJECT_LOG_DIR" ]] && { mkdir -p "$PROJECT_LOG_DIR" || tkl_abort }

    # stdout+stderr redirection into the same log file with handles restore
    {
    {
    {
      exec $0 "$@" 2>&1 1>&8
    } | tee -a "$PROJECT_LOG_FILE" 1>&9
    } 8>&1 | tee -a "$PROJECT_LOG_FILE"
    } 9>&2

    tkl_exit
  }

  IN_GENERATOR_SCRIPT=1

  tkl_include "$PROJECT_SCRIPTS_ROOT/__init__/__init1__.sh" || tkl_abort_include

  (( NEST_LVL+=1 ))


  GenerateConfig || tkl_exit

  tkl_exit
}

main

fi
