#!/bin/bash

[[ -n "$BASH" ]] || return 0 || exit 0 # exit to avoid continue if the return can not be called

if [[ -z "$SOURCE_TACKLELIB_BASH_TACKLELIB_SH" || SOURCE_TACKLELIB_BASH_TACKLELIB_SH -eq 0 ]]; then
  # builtin search
  for BASH_SOURCE_DIR in "/usr/local/bin" "/usr/bin" "/bin"; do
    if [[ -f "$BASH_SOURCE_DIR/bash_tacklelib" ]]; then
      source "$BASH_SOURCE_DIR/bash_tacklelib" || exit $?
      break
    fi
  done
fi

tkl_include_or_abort '__init__.sh'
tkl_include_or_abort 'testlib.sh'

function test_if_math_expr()
{
  tkl_test_assert_false_expr if_math_expr
  tkl_test_assert_true_expr  if_math_expr +0
  tkl_test_assert_true_expr  if_math_expr +1
  tkl_test_assert_true_expr  if_math_expr -0+0
  tkl_test_assert_true_expr  if_math_expr 1/1
  tkl_test_assert_false_expr if_math_expr 1/0
  tkl_test_assert_false_expr if_math_expr 1a

  tkl_test_assert_true_expr  if_math_expr _
  tkl_test_assert_true_expr  if_math_expr __
  tkl_test_assert_true_expr  if_math_expr a
  tkl_test_assert_true_expr  if_math_expr b
  tkl_test_assert_true_expr  if_math_expr c
  tkl_test_assert_true_expr  if_math_expr d
  tkl_test_assert_true_expr  if_math_expr e
  tkl_test_assert_true_expr  if_math_expr f
}

function test_if_int()
{
  tkl_test_assert_false_expr if_int
  tkl_test_assert_true_expr  if_int +0
  tkl_test_assert_true_expr  if_int +1
  tkl_test_assert_false_expr if_int -0+0
  tkl_test_assert_false_expr if_int 1/1
  tkl_test_assert_false_expr if_int 1/0
  tkl_test_assert_false_expr if_int 1a

  tkl_test_assert_false_expr if_int _
  tkl_test_assert_false_expr if_int __
  tkl_test_assert_false_expr if_int a
  tkl_test_assert_false_expr if_int b
  tkl_test_assert_false_expr if_int c
  tkl_test_assert_false_expr if_int d
  tkl_test_assert_false_expr if_int e
  tkl_test_assert_false_expr if_int f
}

function test_cast_to_int()
{
  cast_to_int _ __ a b c d e f

  tkl_test_assert_true '[[ "$_" == "0" ]]'  _
  tkl_test_assert_true '[[ "$__" == "0" ]]' __
  tkl_test_assert_true '[[ "$a" == "+0" ]]' a
  tkl_test_assert_true '[[ "$b" == "-1" ]]' b
  tkl_test_assert_true '[[ "$c" == "0" ]]'  c
  tkl_test_assert_true '[[ "$d" == "0" ]]'  d
  tkl_test_assert_true '[[ "$e" == "0" ]]'  e
  tkl_test_assert_true '[[ "$f" == "0" ]]'  f
}

if [[ -z "$BASH_LINENO" || BASH_LINENO[0] -eq 0 ]]; then
  # Script was not included, then execute it.

  tkl_testmodule_init

  tkl_testmodule_run_test test_if_math_expr
  tkl_testmodule_run_test test_if_int
  tkl_testmodule_run_test test_cast_to_int
fi
