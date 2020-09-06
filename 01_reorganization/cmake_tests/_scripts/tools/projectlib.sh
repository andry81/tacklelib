#!/bin/bash

# Script can be ONLY included by "source" command.
if [[ -n "$BASH" && (-z "$BASH_LINENO" || BASH_LINENO[0] -gt 0) && (-z "$SOURCE_PROJECTLIB_SH" || SOURCE_PROJECTLIB_SH -eq 0) ]]; then

SOURCE_PROJECTLIB_SH=1 # including guard

source '/bin/bash_entry' || exit $?
tkl_include '$TACKLELIB_BASH_SCRIPTS_ROOT/buildlib.sh' || tkl_abort_include

function GenerateConfig()
{
  local CMDLINE_SYSTEM_FILE_IN="$PROJECT_ROOT/cmake_tests/_config/_scripts/01/${BASH_SOURCE_FILE_NAME%[.]*}.system.${BASH_SOURCE_FILE_NAME##*[.]}.in"

  MakeCommandArgumentsFromFile -e "$CMDLINE_SYSTEM_FILE_IN"
  eval "CMAKE_CMD_LINE_SYSTEM=($RETURN_VALUE)"

  tkl_call cmake "${CMAKE_CMD_LINE_SYSTEM[@]}" || return $?

  local CONFIG_FILE_IN="$PROJECT_ROOT/cmake_tests/_config/_scripts/01/${BASH_SOURCE_FILE_NAME%[.]*}.deps.${BASH_SOURCE_FILE_NAME##*[.]}.in"

  local IFS=$'|\t\r\n'
  while read -r ScriptFilePath ScriptCmdLine; do 
    [[ -z "${ScriptFilePath//[$' \t']/}" ]] && continue
    [[ "${ScriptFilePath:i:1}" == "#" ]] && continue
    ScriptCmdLine="${ScriptCmdLine//[$'\r\n']/}" # trim line returns
    declare -a "ScriptCmdLineArr=($ScriptCmdLine)" # evaluate command line only
    tkl_call "$PROJECT_ROOT/$ScriptFilePath" "${ScriptCmdLineArr[@]}" || return $?
  done < "$CONFIG_FILE_IN"

  return 0
}

fi
