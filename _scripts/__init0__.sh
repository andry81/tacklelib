#!/bin/bash

# CAUTION:
#  In case of usage the QtCreator there is set of special broken cases you have to avoid:
#  1. Invalid characters in paths: `(`, `)` and `.`.
#  2. Non english locale in paths.

# Script can be ONLY included by "source" command.
if [[ -n "$BASH" && (-z "$BASH_LINENO" || ${BASH_LINENO[0]} -gt 0) ]]; then 

[[ -z "$NEST_LVL" ]] && NEST_LVL=0

source "${ScriptDirPath:-.}/projectlib.sh" || exit $?

ConvertBackendPathToNative "$ScriptDirPath/.." s || Exit

PROJECT_ROOT="${RETURN_VALUE:-*\$}" # safety: replace by not applicable or unexisted directory if empty
#PROJECT_ROOT="`/bin/readlink -f "$ScriptDirPath/.."`"

CONFIG_VARS_SYSTEM_FILE_IN="$PROJECT_ROOT/config/environment_system.vars.in"
CONFIG_VARS_SYSTEM_FILE="$PROJECT_ROOT/config/environment_system.vars"
CONFIG_VARS_USER_FILE_IN="$PROJECT_ROOT/config/environment_user.vars.in"
CONFIG_VARS_USER_FILE="$PROJECT_ROOT/config/environment_user.vars"

[[ -z "$INIT_VERBOSE" ]] && INIT_VERBOSE=0
[[ -z "$TOOLS_VERBOSE" ]] && TOOLS_VERBOSE=0
[[ -z "$PRINT_VARS_SET" ]] && PRINT_VARS_SET=0

: # resets exit code to 0

fi
