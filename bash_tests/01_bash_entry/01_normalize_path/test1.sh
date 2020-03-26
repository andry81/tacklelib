#!/bin/bash

if [[ -n "$BASH" ]]; then

source '/bin/bash_entry'
tkl_include 'testlib.sh' || exit $?

function test_1()
{
  echo "Test1..."
  tkl_test_assert_true '(( 1 ))'
}

if [[ -z "$BASH_LINENO" || BASH_LINENO[0] -eq 0 ]]; then
  # Script was not included, then execute it.

  tkl_testmodule_init

  tkl_testmodule_run_test test_1
fi

fi
