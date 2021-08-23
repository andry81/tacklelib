#!/bin/bash

if [[ -n "$BASH" ]]; then

source '/bin/bash_entry'
tkl_include 'testlib.sh' || tkl_abort_include

function test_1()
{
  foo()
  {
    tkl_test_echo foo
    boo()
    {
      tkl_push_trap 'tkl_test_echo 2' RETURN
      tkl_test_echo boo
    }
    boo
  }
  foo
  foo
  builtin trap -p RETURN >&3
}

function test_2()
{
  foo()
  {
    tkl_push_trap 'tkl_test_echo 1' RETURN
    tkl_test_echo foo
    boo()
    {
      tkl_push_trap 'tkl_test_echo 2' RETURN
      tkl_test_echo boo
    }
    boo
  }
  foo
  foo
  builtin trap -p RETURN >&3
}

function test_3()
{
  (
    tkl_push_trap 'tkl_test_echo e1' EXIT
    tkl_test_echo 1
    foo()
    {
      (
        tkl_push_trap 'tkl_test_echo r2' RETURN
        tkl_push_trap 'tkl_test_echo e2' EXIT
        tkl_test_echo 2
      )
    }
    foo
    foo
    tkl_test_echo 3
  )
}

if [[ -z "$BASH_LINENO" || BASH_LINENO[0] -eq 0 ]]; then
  # Script was not included, then execute it.

  tkl_testmodule_init

  tkl_testmodule_run_test test_1 foo:boo:2:foo:boo:2
  tkl_testmodule_run_test test_2 foo:boo:2:1:foo:boo:2:1
  tkl_testmodule_run_test test_3 1:2:r2:e2:2:r2:e2:3:e1
fi

fi
