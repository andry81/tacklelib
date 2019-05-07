#!/bin/bash

# Script can be ONLY included by "source" command.
if [[ -n "$BASH" && (-z "$BASH_LINENO" || ${BASH_LINENO[0]} -gt 0) ]]; then 

[[ -z "$NEST_LVL" ]] && NEST_LVL=0

source "${ScriptDirPath:-.}/../../_scripts/buildlib.sh" || exit $?

ConvertBackendPathToNative "$ScriptDirPath/../.." s || Exit

PROJECT_ROOT="${RETURN_VALUE:-*\$}" # safety: replace by not applicable or unexisted directory if empty
TESTS_ROOT="$PROJECT_ROOT/cmake_tests"

: # resets exit code to 0

fi
