#!/bin/bash

# CAUTION:
#  In case of usage the QtCreator there is set of special broken cases you have to avoid:
#  1. Invalid characters in paths: `(`, `)` and `.`.
#  2. Non english locale in paths.

# Script can be ONLY included by "source" command.
if [[ -n "$BASH" && (-z "$BASH_LINENO" || ${BASH_LINENO[0]} -gt 0) ]] && (( ! ${#SOURCE_ROOT_INIT_SH} )); then 

SOURCE_ROOT_INIT_SH=1 # including guard

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

source "${ScriptDirPath:-.}/buildlib.sh"

export PROJECT_ROOT="`/bin/readlink -f "$ScriptDirPath/.."`"

CONFIGURE_FILE_IN="$PROJECT_ROOT/environment_local.vars.in"
CONFIGURE_FILE="$PROJECT_ROOT/environment_local.vars"

if [[ ! -f "$CONFIGURE_FILE" ]]; then
  cat "$CONFIGURE_FILE_IN" > "$CONFIGURE_FILE"
fi

# open file for direct reading by the `read` in the same shell process
exec 9<> "$CONFIGURE_FILE"

# load external variables from file
IFS="="; while read -r -u 9 var value; do
  var="${var%%[#]*}" # cut off comments
  [[ -n "${var//[[:space:]]/}" ]] && {
    value="${value//$'\r'/}" # cleanup from dos/windows text format
    Call export "$var=$value"
  }
done

# close file descriptor
exec 9>&-

export CMAKE_OUTPUT_ROOT="$PROJECT_ROOT/_out"

export CMAKE_GENERATOR_TOOLSET="Unix Makefiles"
export CMAKE_CONFIG_TYPES

# drop exit code
cd .

fi
