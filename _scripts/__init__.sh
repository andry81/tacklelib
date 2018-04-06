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

# Special exit code value variable has used by the specific set of functions
# like `Call` and `Exit` to hold the exit code over the builtin functions like
# `pushd` and `popd` which are changes the real exit code.
LastError=0

export PROJECT_ROOT="`/bin/readlink -f "$ScriptDirPath/.."`"
export CMAKE_OUTPUT_ROOT="$PROJECT_ROOT/_out"

[[ -z "$NEST_LVL" ]] && NEST_LVL=0

# drop exit code
cd .

fi
