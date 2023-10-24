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

tkl_include_or_abort '__init__.sh'
tkl_include_or_abort "$TACKLELIB_BASH_ROOT/tacklelib/testlib.sh"

function TestUserModuleInit()
{
  TEST_SOURCES=()
  TEST_FUNCTIONS=()
  TEST_VARIABLES=(
    _ ''
    __ ''
    a '+0'
    b '-1'
    c '-0+0'
    d '1/1'
    e '1/0'
    f '1a'
  )
}

function TestUserModuleExit() { :; }

function TestUserInit() { :; }

function TestUserExit() { :; }
