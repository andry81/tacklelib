#!/bin/bash

if [[ -n "$BASH" ]]; then

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
tkl_include_or_abort 'testlib.sh'

function test_1_empty()
{
}

function test_2_conditional()
{
}

function test_3_substitution()
{
}

function test_4_escape()
{
}

function test_5_commentary()
{
}

function test_6_specific()
{
}

function test_7_once()
{
}

if [[ -z "$BASH_LINENO" || BASH_LINENO[0] -eq 0 ]]; then
  # Script was not included, then execute it.

  tkl_testmodule_init

  tkl_testmodule_run_test test_1
  tkl_testmodule_run_test test_2
  tkl_testmodule_run_test test_3
  tkl_testmodule_run_test test_4
  tkl_testmodule_run_test test_5
  tkl_testmodule_run_test test_6
  tkl_testmodule_run_test test_7
fi

fi
