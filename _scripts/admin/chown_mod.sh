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

  IFS=$' \t\r\n'
  ScriptBaseInit "$@"
fi

USER="${1:-$USER}"
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
  local IFS=$' \t\r\n'
  echo ">$@"
  "$@"
  LastError=$?
  return $LastError
}

CONFIGURE_ROOT="`/bin/readlink -f "$ScriptDirPath/../.."`"

echo "Updating permissions for user=\"$USER\" and group=\"$GROUP\"..."

Call sudo chown -R ${USER}:${GROUP} "${CONFIGURE_ROOT}"
Call sudo chmod -R ug+rw "${CONFIGURE_ROOT}"

IFS=$' \t\r\n'
for file in `find "${CONFIGURE_ROOT}" -type f -name "*.sh"`; do
  Call sudo chmod ug+x "$file"
done

echo "Done."

fi
