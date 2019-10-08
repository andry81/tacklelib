#!/bin/bash

# Source files generator script.

# Script ONLY for execution.
if [[ -n "$BASH" && (-z "$BASH_LINENO" || ${BASH_LINENO[0]} -eq 0) ]]; then 

source "/bin/bash_entry" || exit $?
tkl_include "__init__/__init0__.sh" || exit $?

(( NEST_LVL++ ))


GenerateSrc || Exit

Exit

fi
