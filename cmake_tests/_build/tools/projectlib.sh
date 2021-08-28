#!/bin/bash

# Script can be ONLY included by "source" command.
if [[ -n "$BASH" && (-z "$BASH_LINENO" || BASH_LINENO[0] -gt 0) && (-z "$SOURCE_PROJECTLIB_SH" || SOURCE_PROJECTLIB_SH -eq 0) ]]; then

SOURCE_PROJECTLIB_SH=1 # including guard

source '/bin/bash_entry' || return $?
tkl_include 'buildlib.sh' || return $?

function GenerateConfig()
{
  local CMDLINE_SYSTEM_FILE_IN="$PROJECT_ROOT/cmake_tests/_config/_build/01/${BASH_SOURCE_FILE_NAME%[.]*}.system.${BASH_SOURCE_FILE_NAME##*[.]}.in"

  MakeCommandArgumentsFromFile -e "$CMDLINE_SYSTEM_FILE_IN"
  eval "CMAKE_CMD_LINE_SYSTEM=($RETURN_VALUE)"

  tkl_call cmake "${CMAKE_CMD_LINE_SYSTEM[@]}" || return $?

  local CONFIG_FILE_IN="$PROJECT_ROOT/cmake_tests/_config/_build/01/${BASH_SOURCE_FILE_NAME%[.]*}.deps.${BASH_SOURCE_FILE_NAME##*[.]}.in"

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

function CheckConfigVersion()
{
  local OPTIONAL_COMPARE="${1:-0}"
  local VARS_SYSTEM_FILE_IN="$2"
  local VARS_SYSTEM_FILE="$3"

  if [[ ! -f "$VARS_SYSTEM_FILE_IN" ]]; then
    echo "$0: error: VARS_SYSTEM_FILE_IN does not exist: \`$VARS_SYSTEM_FILE_IN\`" >&2
    return 3
  fi
  if (( ! OPTIONAL_COMPARE )) && [[ ! -f "$VARS_SYSTEM_FILE" ]]; then
    echo "$0: error: VARS_SYSTEM_FILE does not exist: \`$VARS_SYSTEM_FILE\`" >&2
    return 4
  fi

  if [[ -f "$VARS_SYSTEM_FILE" ]]; then
    # Test input and output files on version equality, otherwise we must stop and warn the user to merge the changes by yourself!
    local IFS=$' \t\r\n'
    read -r CMAKE_FILE_IN_VER_LINE < "$VARS_SYSTEM_FILE_IN"
    read -r CMAKE_FILE_VER_LINE < "$VARS_SYSTEM_FILE"

    if [[ "${CMAKE_FILE_IN_VER_LINE:0:12}" == "#%%%% version:" ]]; then
      if [[ "${CMAKE_FILE_IN_VER_LINE:13}" == "${CMAKE_FILE_VER_LINE:13}" ]]; then
        echo "$0: error: version of \`$VARS_SYSTEM_FILE_IN\` is not equal to version of \`$VARS_SYSTEM_FILE\`, user must merge changes by yourself!" >&2
        return 4
      fi
    fi
  fi

  return 0
}

fi
