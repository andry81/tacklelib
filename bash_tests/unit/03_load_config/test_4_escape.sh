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

function test_4_escape()
{
  LOAD_CONFIG_BARE_FLAGS=--expand-all-vars

  # has no match anyway
  PARAM0='P0'
  PARAM1='P1'

  REFERENCE_4_VALUE_001='%"'
  REFERENCE_4_VALUE_002='%"'
  REFERENCE_4_VALUE_003='%"'

  REFERENCE_4_VALUE_011='%"'
  REFERENCE_4_VALUE_012='%"'
  REFERENCE_4_VALUE_013='%"'

  REFERENCE_4_VALUE_021='*:%"%'
  REFERENCE_4_VALUE_022='*:%"%'
  REFERENCE_4_VALUE_023='*:%"%'

  REFERENCE_4_VALUE_031='*:%"%%'
  REFERENCE_4_VALUE_032='*:%"%%'
  REFERENCE_4_VALUE_033='*:%"%%'

  REFERENCE_4_VALUE_041='%"%"'
  REFERENCE_4_VALUE_042='%"%"'
  REFERENCE_4_VALUE_043='%"%"'


  REFERENCE_4_VALUE_101='"'
  REFERENCE_4_VALUE_102='"'
  REFERENCE_4_VALUE_103='"'

  REFERENCE_4_VALUE_111='$"'
  REFERENCE_4_VALUE_112='$"'
  REFERENCE_4_VALUE_113='$"'

  REFERENCE_4_VALUE_121='*:$/{"}'
  REFERENCE_4_VALUE_122='*:$/{"}'
  REFERENCE_4_VALUE_123='*:$/{"}'

  REFERENCE_4_VALUE_131='*:$/{"}$'
  REFERENCE_4_VALUE_132='*:$/{"}$'
  REFERENCE_4_VALUE_133='*:$/{"}$'

  REFERENCE_4_VALUE_141='$/{"}*:$/{"'
  REFERENCE_4_VALUE_142='$/{"}*:$/{"'
  REFERENCE_4_VALUE_143='$/{"}*:$/{"'


  REFERENCE_4_VALUE_201='^'
  REFERENCE_4_VALUE_202='^'
  REFERENCE_4_VALUE_203='^'

  REFERENCE_4_VALUE_211='^^'
  REFERENCE_4_VALUE_212='^^'
  REFERENCE_4_VALUE_213='^^'

  REFERENCE_4_VALUE_221='\'
  REFERENCE_4_VALUE_222='\'
  REFERENCE_4_VALUE_223='\'

  REFERENCE_4_VALUE_231='\\'
  REFERENCE_4_VALUE_232='\\'
  REFERENCE_4_VALUE_233='\\'

  REFERENCE_4_VALUE_241='"'
  REFERENCE_4_VALUE_242='"'
  REFERENCE_4_VALUE_243='"'

  REFERENCE_4_VALUE_251='^""'
  REFERENCE_4_VALUE_252='^""'
  REFERENCE_4_VALUE_253='^""'

  REFERENCE_4_VALUE_261='^^""'
  REFERENCE_4_VALUE_262='^^""'
  REFERENCE_4_VALUE_263='^^""'

  REFERENCE_4_VALUE_271='\""'
  REFERENCE_4_VALUE_272='\""'
  REFERENCE_4_VALUE_273='\""'

  REFERENCE_4_VALUE_281='\\""'
  REFERENCE_4_VALUE_282='\\""'
  REFERENCE_4_VALUE_283='\\""'

  test_load_config test_4_escape.vars TEST_4_VALUE_ REFERENCE_4_VALUE_ \
    001 002 003 011 012 013 021 022 023 031 032 033 041 042 043 051 052 053 061 062 063 071 072 073 081 082 083 091 092 093 101 102 103 111 112 113 \
                211 212 213 221 222 223 231 232 233 241 242 243 251 252 253 \
                311 312 313 321 322 323 331 332 333 341 342 343 351 352 353
}

if [[ -z "$BASH_LINENO" || BASH_LINENO[0] -eq 0 ]]; then
  # Script was not included, then execute it.

  tkl_testmodule_init

  tkl_testmodule_run_test test_4_escape
fi
