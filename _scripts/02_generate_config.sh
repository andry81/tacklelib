#!/bin/bash

# Configuration variable files generator script.

# Script ONLY for execution.
if [[ -n "$BASH" && (-z "$BASH_LINENO" || ${BASH_LINENO[0]} -eq 0) ]]; then 

IN_GENERATOR_SCRIPT=1

source "/bin/bash_entry" || exit $?

ScriptBaseInit "$@"

source "${ScriptDirPath:-.}/__init1__.sh" || exit $?

(( NEST_LVL+=1 ))


GenerateConfig || Exit

Exit

fi
