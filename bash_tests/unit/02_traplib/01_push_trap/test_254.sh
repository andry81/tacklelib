#!/bin/bash

[[ -n "$BASH" ]] || return 0 || exit 0 # exit to avoid continue if the return can not be called

(( SOURCE_TACKLELIB_BASH_TACKLELIB_SH )) || source bash_tacklelib || return 255 || exit 255 # exit to avoid continue if the return can not be called

tkl_include_or_abort '__init__.sh'
tkl_include_or_abort 'testlib_disabled_sigint.sh'

function test_1()
{
  CONTINUE_ON_SIGINT=1
  foo()
  {
    tkl_push_trap 'tkl_test_echo 1' INT
    tkl_push_trap 'tkl_pop_trap INT' RETURN
    tkl_test_echo foo
    boo()
    {
      tkl_push_trap 'tkl_test_echo 2' INT
      tkl_push_trap 'tkl_pop_trap INT' RETURN
      tkl_test_echo boo
    }
    boo
    sigint_pause 3
  }
  ( foo )
  tkl_test_echo $?
}

function test_2()
{
  CONTINUE_ON_SIGINT=1
  foo()
  {
    tkl_push_trap 'tkl_test_echo 1' INT
    tkl_test_echo foo
    boo()
    {
      tkl_push_trap 'tkl_test_echo 2' INT
      tkl_test_echo boo
      sigint_pause 3
    }
    boo
  }
  ( foo )
  tkl_test_echo $?
}

function test_3()
{
  CONTINUE_ON_SIGINT=1
  foo()
  {
    tkl_push_trap 'tkl_test_echo 1; tkl_set_trap_postponed_exit 1' INT
    tkl_test_echo foo
    boo()
    {
      tkl_push_trap 'tkl_test_echo 2; tkl_set_trap_postponed_exit 2' INT
      tkl_test_echo boo
      sigint_pause 1
    }
    boo
  }
  ( foo )
  tkl_test_echo $?
}

if [[ -z "$BASH_LINENO" || BASH_LINENO[0] -eq 0 ]]; then
  # Script was not included, then execute it.

  tkl_testmodule_init

  tkl_testmodule_run_test test_1 foo:boo:1:130
  tkl_testmodule_run_test test_2 foo:boo:2:1:130
  tkl_testmodule_run_test test_3 foo:boo:2:1:2
fi
