#!/bin/bash

# Script can be ONLY included by "source" command.
if [[ -n "$BASH" && (-z "$BASH_LINENO" || BASH_LINENO[0] -gt 0) ]]; then

tkl_include '../../__init__.sh' || tkl_abort_include
tkl_include "$PROJECT_ROOT/testlib.sh" || tkl_abort_include

function TestUserModuleInit()
{
  TEST_SOURCES=()
  TEST_FUNCTIONS=()
  TEST_VARIABLES=(CWD "$TESTS_ROOT/01_bash_entry/01_normalize_path")
}

function TestUserModuleExit() { :; }

function TestUserInit()
{
  tkl_convert_native_path_to_backend "$CWD"
  CWD="$RETURN_VALUE"
}

function TestUserExit() { :; }

fi
