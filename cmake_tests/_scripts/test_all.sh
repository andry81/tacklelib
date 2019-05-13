#!/bin/bash

# Configurator for cmake with generator.

# Script ONLY for execution.
if [[ -n "$BASH" && (-z "$BASH_LINENO" || ${BASH_LINENO[0]} -eq 0) ]]; then 

source "/bin/bash_entry" || exit $?

ScriptBaseInit "$@"

source "${ScriptDirPath:-.}/__init__.sh" || exit $?

(( NEST_LVL++ ))

TEST_SCRIPT_FILE_NAME="${ScriptFileName%[.]*}"

Call cmake \
  "-DCMAKE_MODULE_PATH=$TESTS_ROOT;$PROJECT_ROOT/cmake" \
  "-DPROJECT_ROOT=$PROJECT_ROOT" \
  "-DTESTS_ROOT=$TESTS_ROOT" \
  "-DTEST_SCRIPT_FILE_NAME=$TEST_SCRIPT_FILE_NAME" \
  -P "$TESTS_ROOT/$TEST_SCRIPT_FILE_NAME.cmake"

Exit

fi
