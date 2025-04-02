#!/bin/bash

[[ -n "$BASH" ]] || return 0 || exit 0 # exit to avoid continue if the return can not be called

(( SOURCE_TACKLELIB_BASH_TACKLELIB_SH )) || source bash_tacklelib || return 255 || exit 255 # exit to avoid continue if the return can not be called

tkl_include_or_abort '__init__.sh'
tkl_include_or_abort 'testlib.sh'

function test_2_conditional()
{
  # has no match anyway
  PARAM0=''
  PARAM1=''

  REFERENCE_2_VALUE_01=0
  REFERENCE_2_VALUE_02=0
  REFERENCE_2_VALUE_03=0
  REFERENCE_2_VALUE_04=0
  REFERENCE_2_VALUE_05=0
  REFERENCE_2_VALUE_06=0

  REFERENCE_2_VALUE_11=''
  REFERENCE_2_VALUE_12=''
  REFERENCE_2_VALUE_13=''

  REFERENCE_2_VALUE_21=2
  REFERENCE_2_VALUE_22=2
  REFERENCE_2_VALUE_23=2

  REFERENCE_2_VALUE_31=3
  REFERENCE_2_VALUE_32=3
  REFERENCE_2_VALUE_33=3

  REFERENCE_2_VALUE_41=''
  REFERENCE_2_VALUE_42=''
  REFERENCE_2_VALUE_43=''

  REFERENCE_2_VALUE_51=''
  REFERENCE_2_VALUE_52=''
  REFERENCE_2_VALUE_53=''

  REFERENCE_2_VALUE_61=''
  REFERENCE_2_VALUE_62=''
  REFERENCE_2_VALUE_63=''

  REFERENCE_2_VALUE_71=''
  REFERENCE_2_VALUE_72=''
  REFERENCE_2_VALUE_73=''

  REFERENCE_2_VALUE_81=''
  REFERENCE_2_VALUE_82=''
  REFERENCE_2_VALUE_83=''

  REFERENCE_2_VALUE_a1=''
  REFERENCE_2_VALUE_a2=''
  REFERENCE_2_VALUE_a3=''

  REFERENCE_2_VALUE_b1=''
  REFERENCE_2_VALUE_b2=''
  REFERENCE_2_VALUE_b3=''

  REFERENCE_2_VALUE_c1=''
  REFERENCE_2_VALUE_c2=''
  REFERENCE_2_VALUE_c3=''

  REFERENCE_2_VALUE_d1=''
  REFERENCE_2_VALUE_d2=''
  REFERENCE_2_VALUE_d3=''

  REFERENCE_2_VALUE_e1=''
  REFERENCE_2_VALUE_e2=''
  REFERENCE_2_VALUE_e3=''

  test_load_config test_2_conditional.vars TEST_2_VALUE_ REFERENCE_2_VALUE_ \
    01 02 03 04 05 06 11 12 13 21 22 23 31 32 33 41 42 43 51 52 53 61 62 63 71 72 73 81 82 83 \
    a1 a2 a3 b1 b2 b3 c1 c2 c3 d1 d2 d3 e1 e2 e3
}

if [[ -z "$BASH_LINENO" || BASH_LINENO[0] -eq 0 ]]; then
  # Script was not included, then execute it.

  tkl_testmodule_init

  tkl_testmodule_run_test test_2_conditional
fi
