#!/bin/bash

[[ -n "$BASH" ]] || return 0 || exit 0 # exit to avoid continue if the return can not be called

if [[ -z "$SOURCE_TACKLELIB_BASH_TACKLELIB_SH" || SOURCE_TACKLELIB_BASH_TACKLELIB_SH -eq 0 ]]; then
  # builtin search
  for BASH_SOURCE_DIR in '/usr/local/bin' '/usr/bin' '/bin'; do
    if [[ -f "$BASH_SOURCE_DIR/bash_tacklelib" ]]; then
      source "$BASH_SOURCE_DIR/bash_tacklelib" || exit $?
      break
    fi
  done
fi

tkl_include_or_abort '__init__.sh'
tkl_include_or_abort 'testlib.sh'

function test_1_empty()
{
  # has no match anyway
  PARAM0=''
  PARAM1=''

  REFERENCE_1_VALUE_01=''
  REFERENCE_1_VALUE_02=''
  REFERENCE_1_VALUE_03=''
  REFERENCE_1_VALUE_04=''
  REFERENCE_1_VALUE_05=''
  REFERENCE_1_VALUE_06=''
  REFERENCE_1_VALUE_07=''
  REFERENCE_1_VALUE_08=''
  REFERENCE_1_VALUE_09=''
  REFERENCE_1_VALUE_10=''

  test_load_config test_1_empty.vars TEST_1_VALUE_ REFERENCE_1_VALUE_ \
    01 02 03 04 05 06 07 08 09 10
}

if [[ -z "$BASH_LINENO" || BASH_LINENO[0] -eq 0 ]]; then
  # Script was not included, then execute it.

  tkl_testmodule_init

  tkl_testmodule_run_test test_1_empty
fi
