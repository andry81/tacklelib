#!/bin/bash

# Script ONLY for execution.
if [[ -n "$BASH" && (-z "$BASH_LINENO" || ${BASH_LINENO[0]} -eq 0) ]]; then 

if [[ "$(type -t ScriptBaseInit)" != "function" ]]; then
  function ScriptBaseInit
  {
    if [[ -n "$BASH_LINENO" ]] && (( ${BASH_LINENO[0]} > 0 )); then
      ScriptFilePath="${BASH_SOURCE[0]//\\//}"
    else
      ScriptFilePath="${0//\\//}"
    fi
    if [[ "${ScriptFilePath:1:1}" == ":" ]]; then
      ScriptFilePath="`/bin/readlink -f "/${ScriptFilePath/:/}"`"
    else
      ScriptFilePath="`/bin/readlink -f "$ScriptFilePath"`"
    fi

    ScriptDirPath="${ScriptFilePath%[/]*}"
    ScriptFileName="${ScriptFilePath##*[/]}"
  }

  ScriptBaseInit "$@"
fi

source "${ScriptDirPath:-.}/../buildlib.sh"

USER=${1:-tester}
GROUP=${2:-tester}

if [[ -z "${USER}" ]]; then
  echo "$ScriptFileName: error: USER argument is not set."
  Exit -255
fi 1>&2

if [[ -z "${GROUP}" ]]; then
  echo "$ScriptFileName: error: GROUP argument is not set."
  Exit -254
fi 1>&2

CONFIGURE_ROOT="`/bin/readlink -f "$ScriptDirPath/../.."`"

Call sudo chown -R ${USER}:${GROUP} "${CONFIGURE_ROOT}"
Call sudo chmod -R ug+rw "${CONFIGURE_ROOT}"
Call sudo chmod -R ug+x "${CONFIGURE_ROOT}/_scripts/*.sh"

fi
