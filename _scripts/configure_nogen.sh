#!/bin/bash

# The script for cases where the IDE or down stream system doesn't have appropriate generator in the cmake.
# For example, it can be the QtCreator.
# To bypass the problem of inconvinient usage of environment variables in such circumstances and unability
# to save them in version control system we have to directly generate cmake include file from a template file
# and do manually change the values in a template. When the IDE starts execution the cmake list then it would
# generate user local cmake from the template and include it loading required set of external variables.
# To prepare this include we use this script.
#

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

source "${ScriptDirPath:-.}/__init__.sh" || exit $?

let NEST_LVL+=1

CONFIGURE_FILE_IN="`/bin/readlink -f "$ScriptDirPath/../$ScriptFileName.in"`"

MakeCommandArgumentsFromFile -e "$CONFIGURE_FILE_IN"

CMAKE_CMD_LINE=("${RETURN_VALUE[@]}")

Pushd "$CMAKE_BUILD_ROOT" && {
  Call cmake "${CMAKE_CMD_LINE[@]}" || { Popd; Exit; }
  Popd
}

Exit

fi
