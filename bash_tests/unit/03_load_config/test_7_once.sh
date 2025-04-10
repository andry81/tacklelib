#!/bin/bash

[[ -n "$BASH" ]] || return 0 || exit 0 # exit to avoid continue if the return can not be called

(( SOURCE_TACKLELIB_BASH_TACKLELIB_SH )) || source bash_tacklelib || return 255 || exit 255 # exit to avoid continue if the return can not be called

tkl_include_or_abort '__init__.sh'
tkl_include_or_abort 'testlib.sh'

function test_7_once()
{
  LOAD_CONFIG_BARE_FLAGS=--expand-all-vars

  # has no match anyway
  PARAM0='P0'
  PARAM1='P1'

  export TEST_7_VALUE_01=XXX
  export TEST_7_VALUE_11=YYY

  REFERENCE_7_VALUE_01='XXX'
  REFERENCE_7_VALUE_02='BBB'

  REFERENCE_7_VALUE_11='YYY'
  REFERENCE_7_VALUE_12='DDD'

  test_load_config test_7_once.vars TEST_7_VALUE_ REFERENCE_7_VALUE_ \
    01 02 \
    11 12
}

if [[ -z "$BASH_LINENO" || BASH_LINENO[0] -eq 0 ]]; then
  # Script was not included, then execute it.

  tkl_testmodule_init

  tkl_testmodule_run_test test_7_once
fi
