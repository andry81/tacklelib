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

USER="${1:-tester}"
GROUP="${2:-$USER}"

if [[ -z "${USER}" ]]; then
  echo "$ScriptFileName: error: USER argument is not set." >&2
  Exit -255
fi

if [[ -z "${GROUP}" ]]; then
  echo "$ScriptFileName: error: GROUP argument is not set." >&2
  Exit -254
fi

function Call()
{
  echo ">$@"
  "$@"
  LastError=$?
  return $LastError
}

CONFIGURE_ROOT="`/bin/readlink -f "$ScriptDirPath/../.."`"

Call sudo chown -R ${USER}:${GROUP} "${CONFIGURE_ROOT}"
Call sudo chmod -R ug+rw "${CONFIGURE_ROOT}"
Call sudo chmod -R ug+x "${CONFIGURE_ROOT}/*.sh"

fi
