#!/bin/bash

# Script can be ONLY included by "source" command.
[[ -n "$BASH" && (-z "$BASH_LINENO" || BASH_LINENO[0] -gt 0) ]] || return 0 || exit 0 # exit to avoid continue if the return can not be called

tkl_include_or_abort "$TACKLELIB_BASH_ROOT/tacklelib/testlib.sh"

function TestUserModuleInit()
{
  TEST_SOURCES=()
  TEST_FUNCTIONS=()
  TEST_VARIABLES=(CWD "$TACKLELIB_BASH_TESTS_PROJECT_ROOT/unit/03_load_config" TEST_DATA_DIR "$TACKLELIB_BASH_TESTS_PROJECT_ROOT/unit/03_load_config/data")
}

function TestUserModuleExit() { :; }

function TestUserInit()
{
  tkl_convert_native_path_to_backend "$CWD"
  CWD="$RETURN_VALUE"
}

function TestUserExit() { :; }
