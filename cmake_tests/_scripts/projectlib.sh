#!/bin/bash

# Script can be ONLY included by "source" command.
if [[ -n "$BASH" && (-z "$BASH_LINENO" || ${BASH_LINENO[0]} -gt 0) ]] && (( ! ${#SOURCE_PROJECTLIB_SH} )); then

SOURCE_PROJECTLIB_SH=1 # including guard

source "/bin/bash_entry" || exit $?
tkl_include "../../_scripts/buildlib.sh" || exit $?

function GenerateConfig()
{
  local CMDLINE_USER_FILE_IN="$PROJECT_ROOT/cmake_tests/_config/_scripts/01/${BASH_SOURCE_FILE_NAME%[.]*}.user.${BASH_SOURCE_FILE_NAME##*[.]}.in"

  MakeCommandArgumentsFromFile -e "$CMDLINE_USER_FILE_IN"
  eval "CMAKE_CMD_LINE_USER=($RETURN_VALUE)"

  Call cmake "${CMAKE_CMD_LINE_USER[@]}" || return $LastError

  local CONFIG_FILE_IN="$PROJECT_ROOT/cmake_tests/_config/_scripts/01/${BASH_SOURCE_FILE_NAME%[.]*}.deps.${BASH_SOURCE_FILE_NAME##*[.]}.in"
  local IFS

  local IFS
  while IFS=$'|\t\r\n' read -r ScriptFilePath ScriptCmdLine; do 
    [[ -z "${ScriptFilePath//[$' \t']/}" ]] && continue
    [[ "${ScriptFilePath:i:1}" == "#" ]] && continue
    ScriptCmdLine="${ScriptCmdLine//[$'\r\n']/}" # trim line returns
    declare -a "ScriptCmdLineArr=($ScriptCmdLine)" # evaluate command line only
    Call "$PROJECT_ROOT/$ScriptFilePath" "${ScriptCmdLineArr[@]}" || return $?
  done < "$CONFIG_FILE_IN"

  return $LastError
} 
function CheckConfigVersion()
{
  local OPTIONAL_COMPARE="${1:-0}"
  local VARS_USER_FILE_IN="$2"
  local VARS_USER_FILE="$3"

  if [[ ! -f "$VARS_USER_FILE_IN" ]]; then
    echo "$0: error: VARS_USER_FILE_IN does not exist: \`$VARS_USER_FILE_IN\`" >&2
    return 3
  fi
  if (( ! OPTIONAL_COMPARE )) && [[ ! -f "$VARS_USER_FILE" ]]; then
    echo "$0: error: VARS_USER_FILE does not exist: \`$VARS_USER_FILE\`" >&2
    return 4
  fi

  if [[ -f "$VARS_USER_FILE" ]]; then
    # Test input and output files on version equality, otherwise we must stop and warn the user to merge the changes by yourself!
    local IFS=$' \t\r\n'
    read -r CMAKE_FILE_IN_VER_LINE < "$VARS_USER_FILE_IN"
    read -r CMAKE_FILE_VER_LINE < "$VARS_USER_FILE"

    if [[ "${CMAKE_FILE_IN_VER_LINE:0:12}" == "#%%%% version:" ]]; then
      if [[ "${CMAKE_FILE_IN_VER_LINE:13}" == "${CMAKE_FILE_VER_LINE:13}" ]]; then
        echo "$0: error: version of \`$VARS_USER_FILE_IN\` is not equal to version of \`$VARS_USER_FILE\`, user must merge changes by yourself!" >&2
        exit 4
      fi
    fi
  fi

  return 0
}

fi
