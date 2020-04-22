#!/bin/bash

# CAUTION:
#  In case of usage the QtCreator there is set of special broken cases you have to avoid:
#  1. Invalid characters in paths: `(`, `)` and `.`.
#  2. Non english locale in paths.

# Script can be ONLY included by "source" command.
if [[ -n "$BASH" && (-z "$BASH_LINENO" || BASH_LINENO[0] -gt 0) && "$TACKLELIB_SCRIPTS_INIT0_DIR" != "$BASH_SOURCE_DIR" ]]; then 

TACKLELIB_SCRIPTS_INIT0_DIR="$BASH_SOURCE_DIR" # including guard

[[ -z "$NEST_LVL" ]] && NEST_LVL=0

tkl_include "../tools/projectlib.sh" || return $?

tkl_convert_backend_path_to_native "$BASH_SOURCE_DIR/../.." s || return $?
PROJECT_ROOT="${RETURN_VALUE:-*:\$}" # safety: replace by not applicable or unexisted directory if empty

tkl_convert_backend_path_to_native "$BASH_SOURCE_DIR/../tools" s || return $?
CONTOOLS_ROOT="${RETURN_VALUE:-*:\$}" # safety: replace by not applicable or unexisted directory if empty

SCRIPTS_LOGS_ROOT="${PROJECT_ROOT:-*:\$}" # safety: replace by not applicable or unexisted directory if empty

CONFIG_VARS_SYSTEM_FILE_IN="$PROJECT_ROOT/_config/environment_system.vars.in"
CONFIG_VARS_SYSTEM_FILE="$PROJECT_ROOT/_config/environment_system.vars"
CONFIG_VARS_USER_FILE_IN="$PROJECT_ROOT/_config/environment_user.vars.in"
CONFIG_VARS_USER_FILE="$PROJECT_ROOT/_config/environment_user.vars"

[[ -z "$INIT_VERBOSE" ]] && INIT_VERBOSE=0
[[ -z "$TOOLS_VERBOSE" ]] && TOOLS_VERBOSE=0
[[ -z "$PRINT_VARS_SET" ]] && PRINT_VARS_SET=0

: # resets exit code to 0

fi
