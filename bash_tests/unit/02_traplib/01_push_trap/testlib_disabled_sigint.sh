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
tkl_include 'testlib.sh' || tkl_abort_include

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
