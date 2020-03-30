#!/bin/bash

# Script can be ONLY included by "source" command.
if [[ -n "$BASH" && (-z "$BASH_LINENO" || BASH_LINENO[0] -gt 0) ]]; then

tkl_include "testlib.sh" || exit $?

sigint_pause()
{
  local key
  echo "Press CTRL-C only $1 time(s) to continue..."$'\n'
  while (( 1 )); do
    read -n1 -r key
  done
}

function TestUserModuleInit_disabled_sigint()
{
  CONTINUE_ON_SIGINT=1
  TEST_FUNCTIONS=("${TEST_FUNCTIONS[@]}" sigint_pause)
  TEST_EXIT_CODES=("${TEST_EXIT_CODES[@]}" test_1 130 test_2 130 test_3 2)
}

fi
