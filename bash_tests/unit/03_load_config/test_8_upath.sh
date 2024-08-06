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

function test_8_upath()
{
  LOAD_CONFIG_BARE_FLAGS=--expand-all-vars

  # has no match anyway
  PARAM0='P0'
  PARAM1='P1'

  REFERENCE_8_VALUE_01='AAA\BBB'
  REFERENCE_8_VALUE_02='BBB\CCC'

  REFERENCE_8_VALUE_11='AAA/BBB/CCC/DDD'
  REFERENCE_8_VALUE_12='BBB/CCC/DDD/EEE'

  REFERENCE_8_VALUE_21='AAA/BBB/CCC/DDD'
  REFERENCE_8_VALUE_22='BBB/CCC/DDD/EEE'

  test_load_config test_8_upath.vars TEST_8_VALUE_ REFERENCE_8_VALUE_ \
    01 02 \
    11 12 \
    21 22
}

if [[ -z "$BASH_LINENO" || BASH_LINENO[0] -eq 0 ]]; then
  # Script was not included, then execute it.

  tkl_testmodule_init

  tkl_testmodule_run_test test_8_upath
fi
