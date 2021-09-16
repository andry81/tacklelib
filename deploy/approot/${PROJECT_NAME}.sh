#!/bin/bash

# Description:
#   An application runner to fix application library dependecies and log the output.
#

# Script ONLY for execution.
if [[ -n "$BASH" && (-z "$BASH_LINENO" || ${BASH_LINENO[0]} -eq 0) ]]; then 

source '/bin/bash_tacklelib' || exit $?

# no local logging if nested call
(( ! IMPL_MODE && ! NEST_LVL )) && {
  export IMPL_MODE=1
  exec 3>&1 4>&2
  trap 'exec 2>&4 1>&3' EXIT

  # date time request base on: https://stackoverflow.com/questions/1401482/yyyy-mm-dd-format-date-in-shell-script/1401495#1401495
  #

  function GetTime()
  {
    # RANDOM instead of milliseconds
    case $BASH_VERSION in
      # < 4.2
      [123].* | 4.[01] | 4.0* | 4.1[^0-9]*)
        PROJECT_LOG_FILE_NAME_SUFFIX=$(date "+%Y'%m'%d_%H'%M'%S''")$(( RANDOM % 1000 ))
        ;;
      # >= 4.2
      *)
        printf -v PROJECT_LOG_FILE_NAME_SUFFIX "%(%Y'%m'%d_%H'%M'%S'')T$(( RANDOM % 1000 ))" -1
        ;;
    esac
  }

  GetTime

  PROJECT_LOG_DIR="$BASH_SOURCE_DIR/.log/$PROJECT_LOG_FILE_NAME_SUFFIX.${BASH_SOURCE_FILE_NAME%[.]*}"
  PROJECT_LOG_FILE="$PROJECT_LOG_DIR/${PROJECT_LOG_FILE_NAME_SUFFIX}.${BASH_SOURCE_FILE_NAME%[.]*}.log"

  [[ ! -e "$PROJECT_LOG_DIR" ]] && { mkdir -p "$PROJECT_LOG_DIR" || tkl_abort 11; }

  # stdout+stderr redirection into the same log file with handles restore
  {
  {
  {
    exec $0 "$@" 2>&1 1>&8
  } | tee -a "$PROJECT_LOG_FILE" 1>&9
  } 8>&1 | tee -a "$PROJECT_LOG_FILE"
  } 9>&2

  exit $?
}

function CallLr()
{
  echo ">$@"
  "$@"
  LastError=$?
  echo
  return $LastError
} 

function Call()
{
  echo ">$@"
  "$@"
  LastError=$?
  return $LastError
} 

# WORKAROUND for `file is not found` when run from GUI shell
cd "$BASH_SOURCE_DIR"

echo
echo "----"
echo "---- Start time: $PROJECT_LOG_FILE_NAME_SUFFIX"
echo "---- CWD=\"$(pwd)\""
echo "----"

# export variables
Call export LD_LIBRARY_PATH=".:./lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
#export QT_QPA_FONTDIR=./lib/fonts

CallLr "$BASH_SOURCE_DIR/${BASH_SOURCE_FILE_NAME%[.]*}" "$@"

GetTime

echo "----"
echo "---- End time: $PROJECT_LOG_FILE_NAME_SUFFIX"
echo "---- Exit code: $LastError"
echo "----"
echo

fi
