#!/bin/bash

if [[ -n "$BASH" ]]; then

source '/bin/bash_entry'
tkl_include 'testlib.sh' || exit $?

tkl_testmodule_init

function RunAllTests()
{
  tkl_testmodule_run_test test_1
}

function test_1()
{
  echo "Test1..."
}

RunAllTests

fi
