#!/bin/bash

# Script can be ONLY included by "source" command.
[[ -z "$BASH" || (-n "$BASH_LINENO" && BASH_LINENO[0] -le 0) ]] && return

if [[ -z "$SOURCE_TACKLELIB_BASH_TACKLELIB_SH" || SOURCE_TACKLELIB_BASH_TACKLELIB_SH -eq 0 ]]; then
  # builtin search
  for BASH_SOURCE_DIR in "/usr/local/bin" "/usr/bin" "/bin"; do
    [[ -f "$BASH_SOURCE_DIR/bash_tacklelib" ]] && {
      source "$BASH_SOURCE_DIR/bash_tacklelib" || exit $?
      break
    }
  done
fi

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
