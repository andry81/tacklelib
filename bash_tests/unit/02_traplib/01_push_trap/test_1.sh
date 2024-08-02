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
