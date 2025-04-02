#!/bin/bash

[[ -n "$BASH" ]] || return 0 || exit 0 # exit to avoid continue if the return can not be called

(( SOURCE_TACKLELIB_BASH_TACKLELIB_SH )) || source bash_tacklelib || return 255 || exit 255 # exit to avoid continue if the return can not be called

tkl_include_or_abort '__init__.sh'
tkl_include_or_abort 'testlib.sh'

function test_6_specific()
{
  LOAD_CONFIG_BARE_FLAGS=--expand-all-vars

  # has no match anyway
  PARAM0='P0'
  PARAM1='P1'

  REFERENCE_6_VALUE_01='='
  REFERENCE_6_VALUE_02='=1'
  REFERENCE_6_VALUE_03='=1'
  REFERENCE_6_VALUE_04='=1	 1'
  REFERENCE_6_VALUE_05='= 1	 1'
  REFERENCE_6_VALUE_06='= 1	 1	 '
  REFERENCE_6_VALUE_07='1	 =='
  REFERENCE_6_VALUE_08='='
  REFERENCE_6_VALUE_09='	 '
  REFERENCE_6_VALUE_10=\''	 "'
  REFERENCE_6_VALUE_11='"	 '\'
  REFERENCE_6_VALUE_12="'	 '"

  test_load_config test_6_specific.vars TEST_6_VALUE_ REFERENCE_6_VALUE_ \
    01 02 03 04 05 06 07 08 09 10 11 12
}

if [[ -z "$BASH_LINENO" || BASH_LINENO[0] -eq 0 ]]; then
  # Script was not included, then execute it.

  tkl_testmodule_init

  tkl_testmodule_run_test test_6_specific
fi
