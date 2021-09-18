#!/bin/bash

if [[ -n "$BASH" ]]; then

source '/bin/bash_tacklelib' || exit $?
tkl_include '__init__.sh' || tkl_abort_include
tkl_include 'testlib.sh' || tkl_abort_include

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
