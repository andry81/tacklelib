#!/bin/bash

# Configurator for cmake with generator.

# Script ONLY for execution.
if [[ -n "$BASH" && (-z "$BASH_LINENO" || ${BASH_LINENO[0]} -eq 0) ]]; then 

source "/bin/bash_entry" || exit $?
tkl_include "__init__/__init1__.sh" || exit $?

(( NEST_LVL++ ))

source "$PROJECT_ROOT/_scripts/tools/set_vars_from_files.sh" || Exit
source "$PROJECT_ROOT/_scripts/tools/get_GENERATOR_IS_MULTI_CONFIG.sh" || Exit


# CAUTION: an empty value and `*` value has different meanings!
#
CMAKE_BUILD_TYPE="$1"

UpdateOsName

# preload configuration files only to make some checks
Call set_vars_from_files \
  "${CONFIG_VARS_SYSTEM_FILE//;/\\;}" "$OS_NAME" . . . ";" \
  --exclude_vars_filter "PROJECT_ROOT" \
  --ignore_late_expansion_statements || Exit

# check if selected generator is a multiconfig generator
Call get_GENERATOR_IS_MULTI_CONFIG "$CMAKE_GENERATOR" || Exit

if (( GENERATOR_IS_MULTI_CONFIG )); then
  # CMAKE_CONFIG_TYPES must not be defined
  if [[ -n "$CMAKE_BUILD_TYPE" ]]; then
    echo "$0: error: declared cmake generator is a multiconfig generator, CMAKE_BUILD_TYPE must not be defined: CMAKE_GENERATOR=\`$CMAKE_GENERATOR\` CMAKE_BUILD_TYPE=\`$CMAKE_BUILD_TYPE\`." >&2
    Exit 127
  fi
else
  # CMAKE_CONFIG_TYPES must be defined
  if [[ -z "$CMAKE_BUILD_TYPE" ]]; then
    echo "$0: error: declared cmake generator is not a multiconfig generator, CMAKE_BUILD_TYPE must be defined: CMAKE_GENERATOR=\`$CMAKE_GENERATOR\` CMAKE_BUILD_TYPE=\`$CMAKE_BUILD_TYPE\`." >&2
    Exit 128
  fi
fi

if [[ "$CMAKE_BUILD_TYPE" == "*" ]]; then
  IFS=$'; \t\r\n'; for CMAKE_BUILD_TYPE in $CMAKE_CONFIG_TYPES; do
    Configure || Exit
  done
else
  Configure || Exit
fi

Exit

fi
