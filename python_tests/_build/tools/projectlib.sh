#!/bin/bash

# Script can be ONLY included by "source" command.
[[ -n "$BASH" && (-z "$BASH_LINENO" || BASH_LINENO[0] -gt 0) ]] && (( ! SOURCE_TACKLELIB_PYTHON_TESTS_BUILD_TOOLS_PROJECTLIB_SH )) || return 0 || exit 0 # exit to avoid continue if the return can not be called

SOURCE_TACKLELIB_PYTHON_TESTS_BUILD_TOOLS_PROJECTLIB_SH=1 # including guard

(( SOURCE_TACKLELIB_BASH_TACKLELIB_SH )) || source bash_tacklelib || return 255 || exit 255 # exit to avoid continue if the return can not be called

tkl_include_or_abort "$TACKLELIB_BASH_ROOT/tacklelib/buildlib.sh"

tkl_include_or_abort "$TACKLELIB_PROJECT_BUILD_ROOT/tools/projectlib.sh"

function GenerateConfig()
{
  local CMDLINE_SYSTEM_FILE_IN="$TESTS_PROJECT_INPUT_CONFIG_ROOT/_build/${BASH_SOURCE_FILE_NAME%[.]*}/config.system.${BASH_SOURCE_FILE_NAME##*[.]}.in"

  tkl_load_command_line_from_file -e "$CMDLINE_SYSTEM_FILE_IN"
  eval "CMAKE_CMD_LINE_SYSTEM=($RETURN_VALUE)"

  tkl_call cmake "${CMAKE_CMD_LINE_SYSTEM[@]}" || tkl_abort $?

  local CMD_LIST_FILE_IN="$TESTS_PROJECT_INPUT_CONFIG_ROOT/_build/${BASH_SOURCE_FILE_NAME%[.]*}/cmd_list.${BASH_SOURCE_FILE_NAME##*[.]}.in"

  local IFS=$'|\t\r\n'
  while read -r CmdPath CmdParams; do 
    [[ -z "${CmdPath//[$' \t']/}" ]] && continue
    [[ "${CmdPath:i:1}" == "#" ]] && continue
    CmdParams="${CmdParams//[$'\r\n']/}" # trim line returns
    declare -a "CmdParamsArr=($CmdParams)" # evaluate command line only
    tkl_call "$TESTS_PROJECT_ROOT/$CmdPath" "${CmdParamsArr[@]}" || tkl_abort $?
  done < "$CMD_LIST_FILE_IN"

  return 0
}
