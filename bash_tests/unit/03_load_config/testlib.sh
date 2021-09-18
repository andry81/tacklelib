#!/bin/bash

# Script can be ONLY included by "source" command.
[[ -z "$BASH" || (-n "$BASH_LINENO" && BASH_LINENO[0] -le 0) ]] && return

source '/bin/bash_tacklelib' || exit $?
tkl_include '__init__.sh' || tkl_abort_include
tkl_include "$TACKLELIB_BASH_ROOT/tacklelib/testlib.sh" || tkl_abort_include

function TestUserModuleInit()
{
  TEST_SOURCES=()
  TEST_FUNCTIONS=()
  TEST_VARIABLES=(CWD "$TESTS_PROJECT_ROOT/unit/03_load_config" TEST_DATA_DIR "$TESTS_PROJECT_ROOT/unit/03_load_config/data")
}

function TestUserModuleExit() { :; }

function TestUserInit()
{
  tkl_convert_native_path_to_backend "$CWD"
  CWD="$RETURN_VALUE"
}

function TestUserExit() { :; }
