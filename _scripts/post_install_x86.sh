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

source "${ScriptDirPath:-.}/__init__.sh" || exit $?

let NEST_LVL+=1

#Call "${ScriptDirPath:-.}/build_x86.sh" "$@" || Exit
#echo

CMAKE_BUILD_TYPE="$1"
CMAKE_BUILD_TARGET="$2"

[[ -z "${CMAKE_BUILD_TYPE}" ]] && CMAKE_BUILD_TYPE="*" # target all configurations
[[ -z "${CMAKE_BUILD_TARGET}" ]] && CMAKE_BUILD_TARGET="*"

FILE_DEPS_ROOT_LIST="*.so:*.so.*:*.a:*.a.*"
FILE_DEPS_LIST_TO_FIND="." #":./plugins/platforms"
FILE_DEPS_LIST_TO_EXCLUDE="linux-gate.so.1"
FILE_DEPS_LD_PATH_LIST="." #":./plugins/platforms:$QT5_ROOT/lib"
FILE_DEPS_MKDIR_LIST="_scripts:_scripts/admin:_scripts/deploy:lib" #":plugins:plugins/platforms"
FILE_DEPS_CPDIR_LIST="" #"$QT5_ROOT/plugins/platforms/.:./plugins/platforms"

if [[ "$CMAKE_BUILD_TYPE" == "*" ]]; then
  for CMAKE_BUILD_TYPE in $CMAKE_CONFIG_TYPES; do
    PostInstall || Exit
  done
else
  PostInstall
fi

Exit

fi
