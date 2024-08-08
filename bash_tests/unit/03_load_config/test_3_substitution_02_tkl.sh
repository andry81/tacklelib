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

function test_3_substitution_02_tkl()
{
  LOAD_CONFIG_BARE_FLAGS=--expand-tkl-vars

  # has no match anyway
  PARAM0=''
  PARAM1='P1'

  REFERENCE_3_VALUE_011='*:$/{'
  REFERENCE_3_VALUE_012='*:$/{'
  REFERENCE_3_VALUE_013='*:$/{'

  REFERENCE_3_VALUE_021='*:$/{}'
  REFERENCE_3_VALUE_022='*:$/{}'
  REFERENCE_3_VALUE_023='*:$/{}'

  REFERENCE_3_VALUE_031='$/{}*:$/{'
  REFERENCE_3_VALUE_032='$/{}*:$/{'
  REFERENCE_3_VALUE_033='$/{}*:$/{'

  REFERENCE_3_VALUE_041='$$'
  REFERENCE_3_VALUE_042='$$'
  REFERENCE_3_VALUE_043='$$'

  REFERENCE_3_VALUE_051='*:$/{ }'
  REFERENCE_3_VALUE_052='*:$/{ }'
  REFERENCE_3_VALUE_053='*:$/{ }'

  REFERENCE_3_VALUE_061='$/{ }*:$/{'
  REFERENCE_3_VALUE_062='$/{ }*:$/{'
  REFERENCE_3_VALUE_063='$/{ }*:$/{'

  REFERENCE_3_VALUE_071='*:$/{ $/$'
  REFERENCE_3_VALUE_072='*:$/{ $/$'
  REFERENCE_3_VALUE_073='*:$/{ $/$'

  REFERENCE_3_VALUE_081='*:$/{X'
  REFERENCE_3_VALUE_082='*:$/{X'
  REFERENCE_3_VALUE_083='*:$/{X'

  REFERENCE_3_VALUE_091='X*:$/{'
  REFERENCE_3_VALUE_092='X*:$/{'
  REFERENCE_3_VALUE_093='X*:$/{'

  REFERENCE_3_VALUE_101='*:$/{X}'
  REFERENCE_3_VALUE_102='*:$/{X}'
  REFERENCE_3_VALUE_103='*:$/{X}'

  REFERENCE_3_VALUE_111='$/{X}$'
  REFERENCE_3_VALUE_112='$/{X}$'
  REFERENCE_3_VALUE_113='$/{X}$'


  REFERENCE_3_VALUE_201='*:$/{TEST_3_VALUE_000}'
  REFERENCE_3_VALUE_202='*:$/{TEST_3_VALUE_000}'
  REFERENCE_3_VALUE_203='*:$/{TEST_3_VALUE_000}'

  REFERENCE_3_VALUE_211='*:$/{TEST_3_VALUE_000}*:$/{TEST_3_VALUE_000}'
  REFERENCE_3_VALUE_212='*:$/{TEST_3_VALUE_000}*:$/{TEST_3_VALUE_000}'
  REFERENCE_3_VALUE_213='*:$/{TEST_3_VALUE_000}*:$/{TEST_3_VALUE_000}'

  REFERENCE_3_VALUE_221='*:$/{TEST_3_VALUE_000}$/{TEST_3_VALUE_000}'
  REFERENCE_3_VALUE_222='*:$/{TEST_3_VALUE_000}$/{TEST_3_VALUE_000}'
  REFERENCE_3_VALUE_223='*:$/{TEST_3_VALUE_000}$/{TEST_3_VALUE_000}'

  REFERENCE_3_VALUE_231='*:$/{TEST_3_VALUE_000}*:$/{'
  REFERENCE_3_VALUE_232='*:$/{TEST_3_VALUE_000}*:$/{'
  REFERENCE_3_VALUE_233='*:$/{TEST_3_VALUE_000}*:$/{'

  REFERENCE_3_VALUE_241='*:$/{TEST_3_VALUE_000}$'
  REFERENCE_3_VALUE_242='*:$/{TEST_3_VALUE_000}$'
  REFERENCE_3_VALUE_243='*:$/{TEST_3_VALUE_000}$'

  REFERENCE_3_VALUE_251='$/{TEST_3_VALUE_000}$'
  REFERENCE_3_VALUE_252='$/{TEST_3_VALUE_000}$'
  REFERENCE_3_VALUE_253='$/{TEST_3_VALUE_000}$'


  REFERENCE_3_VALUE_301='*:$/{'
  REFERENCE_3_VALUE_302='*:$/{'
  REFERENCE_3_VALUE_303='*:$/{'

  REFERENCE_3_VALUE_311='*:$/{*:$/{'
  REFERENCE_3_VALUE_312='*:$/{*:$/{'
  REFERENCE_3_VALUE_313='*:$/{*:$/{'

  REFERENCE_3_VALUE_321='*:$/{$/{TEST_3_VALUE_011}'
  REFERENCE_3_VALUE_322='*:$/{$/{TEST_3_VALUE_012}'
  REFERENCE_3_VALUE_323='*:$/{$/{TEST_3_VALUE_013}'

  REFERENCE_3_VALUE_331='*:$/{*:$/{'
  REFERENCE_3_VALUE_332='*:$/{*:$/{'
  REFERENCE_3_VALUE_333='*:$/{*:$/{'

  REFERENCE_3_VALUE_341='*:$/{$'
  REFERENCE_3_VALUE_342='*:$/{$'
  REFERENCE_3_VALUE_343='*:$/{$'

  REFERENCE_3_VALUE_351='$/{TEST_3_VALUE_011}$'
  REFERENCE_3_VALUE_352='$/{TEST_3_VALUE_012}$'
  REFERENCE_3_VALUE_353='$/{TEST_3_VALUE_013}$'

  test_load_config test_3_substitution_02_tkl.vars TEST_3_VALUE_ REFERENCE_3_VALUE_ \
                011 012 013 021 022 023 031 032 033 041 042 043 051 052 053 061 062 063 071 072 073 081 082 083 091 092 093 101 102 103 111 112 113 \
    201 202 203 211 212 213 221 222 223 231 232 233 241 242 243 251 252 253 \
    301 302 303 311 312 313 321 322 323 331 332 333 341 342 343 351 352 353
}

if [[ -z "$BASH_LINENO" || BASH_LINENO[0] -eq 0 ]]; then
  # Script was not included, then execute it.

  tkl_testmodule_init

  tkl_testmodule_run_test test_3_substitution_02_tkl
fi