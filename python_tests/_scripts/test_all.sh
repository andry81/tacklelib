#!/bin/bash

# Script ONLY for execution.
if [[ -n "$BASH" && (-z "$BASH_LINENO" || ${BASH_LINENO[0]} -eq 0) ]]; then 

source "/bin/bash_entry" || exit $?
tkl_include "__init__/__init1__.sh" || exit $?

(( NEST_LVL++ ))

source "$PROJECT_ROOT/_scripts/tools/set_vars_from_files.sh" || Exit

UpdateOsName

# preload configuration files only to make some checks
Call set_vars_from_files \
  "${CONFIG_VARS_SYSTEM_FILE//;/\\;}" "$OS_NAME" . . . ";" \
  --exclude_vars_filter "PROJECT_ROOT" \
  --ignore_late_expansion_statements || Exit

Pushd "$TESTS_ROOT/01_unit" && {
  Call "$PYTEST_EXE_PATH" || { Popd; Exit; }
  Popd
}

Exit

fi
