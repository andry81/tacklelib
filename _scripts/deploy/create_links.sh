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

if [[ ! -f "$ScriptDirPath/links.vars" ]]; then
  echo "$ScriptFileName: error: links.vars is not found: \"$ScriptDirPath/links.vars\""
  exit 1
fi 1>&2

APP_ROOT="`readlink -f "$ScriptDirPath/.."`"

CONFIGURE_ROOT="$1"

if [[ -z "$CONFIGURE_ROOT" || ! -d "$CONFIGURE_ROOT/" ]]; then
  CONFIGURE_ROOT="$APP_ROOT/lib"
  [[ ! -d "$CONFIGURE_ROOT" ]] && CONFIGURE_ROOT="$APP_ROOT"
else
  CONFIGURE_ROOT="`readlink -f "$CONFIGURE_ROOT"`"
fi

[[ ! -d "$CONFIGURE_ROOT/" ]] && mkdir "$CONFIGURE_ROOT"

pushd "$CONFIGURE_ROOT" > /dev/null && {
  while read -r LinkPath RefPath; do
    if [[ -n "$LinkPath" ]]; then
      echo "'$LinkPath' -> '$RefPath'"
      ln -s "$RefPath" "$LinkPath"
    fi
  done < "$ScriptDirPath/links.vars"
  popd > /dev/null
}

fi 
