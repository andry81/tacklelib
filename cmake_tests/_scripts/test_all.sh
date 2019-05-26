#!/bin/bash

# Configurator for cmake with generator.

# Script ONLY for execution.
if [[ -n "$BASH" && (-z "$BASH_LINENO" || ${BASH_LINENO[0]} -eq 0) ]]; then 

source "/bin/bash_entry" || exit $?

ScriptBaseInit "$@"

source "${ScriptDirPath:-.}/__init__.sh" || exit $?

(( NEST_LVL++ ))

IFS=$' \t\r\n'
Call cmake \
  "-DCMAKE_MODULE_PATH=$TESTS_ROOT;$PROJECT_ROOT/cmake" \
  "-DPROJECT_ROOT=$PROJECT_ROOT" \
  "-DTESTS_ROOT=$TESTS_ROOT" \
  "-DTACKLELIB_TESTLIB_TESTSCRIPT_FILE=$TESTS_ROOT/${ScriptFileName%[.]*}.cmake" \
  "-DTACKLELIB_TESTLIB_ROOT=$PROJECT_ROOT/cmake/tacklelib/testlib" \
  -P \
  "$PROJECT_ROOT/cmake/tacklelib/testlib/tools/RunTestLib.cmake" \
  "$@"

Exit

fi
