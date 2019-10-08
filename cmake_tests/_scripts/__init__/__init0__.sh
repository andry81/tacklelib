#!/bin/bash

# Script can be ONLY included by "source" command.
if [[ -n "$BASH" && (-z "$BASH_LINENO" || ${BASH_LINENO[0]} -gt 0) ]]; then 

[[ -z "$NEST_LVL" ]] && NEST_LVL=0

tkl_include "../tools/projectlib.sh" || exit $?

tkl_convert_backend_path_to_native "$BASH_SOURCE_DIR/../../.." s || Exit

PROJECT_ROOT="${RETURN_VALUE:-*\$}" # safety: replace by not applicable or unexisted directory if empty
TESTS_ROOT="$PROJECT_ROOT/cmake_tests"

CONFIG_VARS_SYSTEM_FILE_IN="$PROJECT_ROOT/cmake_tests/_config/environment_system.vars.in"
CONFIG_VARS_SYSTEM_FILE="$PROJECT_ROOT/cmake_tests/_config/environment_system.vars"

[[ -z "$INIT_VERBOSE" ]] && INIT_VERBOSE=0
[[ -z "$TOOLS_VERBOSE" ]] && TOOLS_VERBOSE=0
[[ -z "$PRINT_VARS_SET" ]] && PRINT_VARS_SET=0

: # resets exit code to 0 

fi
