#!/bin/bash

if [[ -n "$BASH" ]]; then

if [[ -z "$SOURCE_TACKLELIB_BASH_TACKLELIB_SH" || SOURCE_TACKLELIB_BASH_TACKLELIB_SH -eq 0 ]]; then
  # builtin search
  for BASH_SOURCE_DIR in "/usr/local/bin" "/usr/bin" "/bin"; do
    [[ -f "$BASH_SOURCE_DIR/bash_tacklelib" ]] && {
      source "$BASH_SOURCE_DIR/bash_tacklelib" || exit $?
      break
    }
  done
fi

tkl_include '__init__.sh' || tkl_abort_include
tkl_include 'testlib.sh' || tkl_abort_include

function test_1()
{
  local last_error

  tkl_normalize_path .
  last_error=$?
  tkl_test_assert_true '[[ "$RETURN_VALUE" == "." ]]' RETURN_VALUE
  tkl_test_assert_true '(( ! last_error ))' last_error

  case "$OSTYPE" in
    cygwin* | msys* | mingw*)
      shopt -s nocasematch
    ;;
  esac

  tkl_normalize_path . -a
  last_error=$?
  tkl_test_assert_true '[[ "$RETURN_VALUE" == "$CWD" ]]' RETURN_VALUE $CWD
  tkl_test_assert_true '(( ! last_error ))' last_error
}

function test_2()
{
  local last_error

  tkl_normalize_path 'c:/'
  last_error=$?
  tkl_test_assert_true '[[ "$RETURN_VALUE" == "c:/" ]]' RETURN_VALUE
  tkl_test_assert_true '(( ! last_error ))' last_error

  tkl_normalize_path 'c:/' -a
  last_error=$?
  tkl_test_assert_true '[[ "$RETURN_VALUE" == "c:/" ]]' RETURN_VALUE
  tkl_test_assert_true '(( ! last_error ))' last_error

  tkl_normalize_path 'c:\'
  last_error=$?
  tkl_test_assert_true '[[ "$RETURN_VALUE" == "c:/" ]]' RETURN_VALUE
  tkl_test_assert_true '(( ! last_error ))' last_error

  tkl_normalize_path 'c:\\' -a
  last_error=$?
  tkl_test_assert_true '[[ "$RETURN_VALUE" == "c:/" ]]' RETURN_VALUE
  tkl_test_assert_true '(( ! last_error ))' last_error
}

function test_3()
{
  local last_error

  tkl_normalize_path 'c://.'
  last_error=$?
  tkl_test_assert_true '[[ "$RETURN_VALUE" == "c:/" ]]' RETURN_VALUE
  tkl_test_assert_true '(( ! last_error ))' last_error

  tkl_normalize_path 'c://.' -a
  last_error=$?
  tkl_test_assert_true '[[ "$RETURN_VALUE" == "c:/" ]]' RETURN_VALUE
  tkl_test_assert_true '(( ! last_error ))' last_error

  tkl_normalize_path 'c:\\.'
  last_error=$?
  tkl_test_assert_true '[[ "$RETURN_VALUE" == "c:/" ]]' RETURN_VALUE
  tkl_test_assert_true '(( ! last_error ))' last_error

  tkl_normalize_path 'c:\\.' -a
  last_error=$?
  tkl_test_assert_true '[[ "$RETURN_VALUE" == "c:/" ]]' RETURN_VALUE
  tkl_test_assert_true '(( ! last_error ))' last_error


  tkl_normalize_path 'c:/.//'
  last_error=$?
  tkl_test_assert_true '[[ "$RETURN_VALUE" == "c:/" ]]' RETURN_VALUE
  tkl_test_assert_true '(( ! last_error ))' last_error

  tkl_normalize_path 'c:/.//' -a
  last_error=$?
  tkl_test_assert_true '[[ "$RETURN_VALUE" == "c:/" ]]' RETURN_VALUE
  tkl_test_assert_true '(( ! last_error ))' last_error

  tkl_normalize_path 'c:\.\\'
  last_error=$?
  tkl_test_assert_true '[[ "$RETURN_VALUE" == "c:/" ]]' RETURN_VALUE
  tkl_test_assert_true '(( ! last_error ))' last_error

  tkl_normalize_path 'c:\.\\' -a
  last_error=$?
  tkl_test_assert_true '[[ "$RETURN_VALUE" == "c:/" ]]' RETURN_VALUE
  tkl_test_assert_true '(( ! last_error ))' last_error
}

function test_4()
{
  local last_error

  tkl_normalize_path 'c://..'
  last_error=$?
  tkl_test_assert_true '[[ "$RETURN_VALUE" == "c:/.." ]]' RETURN_VALUE
  tkl_test_assert_true '(( ! last_error ))' last_error

  tkl_normalize_path 'c://..' -a
  last_error=$?
  tkl_test_assert_true '[[ "$RETURN_VALUE" == "c:/.." ]]' RETURN_VALUE
  tkl_test_assert_true '(( ! last_error ))' last_error

  tkl_normalize_path 'c:\\..'
  last_error=$?
  tkl_test_assert_true '[[ "$RETURN_VALUE" == "c:/.." ]]' RETURN_VALUE
  tkl_test_assert_true '(( ! last_error ))' last_error

  tkl_normalize_path 'c:\\..' -a
  last_error=$?
  tkl_test_assert_true '[[ "$RETURN_VALUE" == "c:/.." ]]' RETURN_VALUE
  tkl_test_assert_true '(( ! last_error ))' last_error


  tkl_normalize_path 'c://../..'
  last_error=$?
  tkl_test_assert_true '[[ "$RETURN_VALUE" == "c:/../.." ]]' RETURN_VALUE
  tkl_test_assert_true '(( ! last_error ))' last_error

  tkl_normalize_path 'c://../..' -a
  last_error=$?
  tkl_test_assert_true '[[ "$RETURN_VALUE" == "c:/../.." ]]' RETURN_VALUE
  tkl_test_assert_true '(( ! last_error ))' last_error

  tkl_normalize_path 'c:\\..\\..'
  last_error=$?
  tkl_test_assert_true '[[ "$RETURN_VALUE" == "c:/../.." ]]' RETURN_VALUE
  tkl_test_assert_true '(( ! last_error ))' last_error

  tkl_normalize_path 'c:\\..\\..' -a
  last_error=$?
  tkl_test_assert_true '[[ "$RETURN_VALUE" == "c:/../.." ]]' RETURN_VALUE
  tkl_test_assert_true '(( ! last_error ))' last_error
}

function test_5()
{
  local last_error

  case "$OSTYPE" in
    cygwin* | msys* | mingw*)
      shopt -s nocasematch
    ;;
  esac

  tkl_normalize_path 'a/../b'
  last_error=$?
  tkl_test_assert_true '[[ "$RETURN_VALUE" == "b" ]]' RETURN_VALUE
  tkl_test_assert_true '(( ! last_error ))' last_error

  tkl_normalize_path 'a/../b' -a
  last_error=$?
  tkl_test_assert_true '[[ "$RETURN_VALUE" == "$CWD/b" ]]' RETURN_VALUE CWD
  tkl_test_assert_true '(( ! last_error ))' last_error

  tkl_normalize_path 'a\..\b'
  last_error=$?
  tkl_test_assert_true '[[ "$RETURN_VALUE" == "b" ]]' RETURN_VALUE
  tkl_test_assert_true '(( ! last_error ))' last_error

  tkl_normalize_path 'a\..\b' -a
  last_error=$?
  tkl_test_assert_true '[[ "$RETURN_VALUE" == "$CWD/b" ]]' RETURN_VALUE CWD
  tkl_test_assert_true '(( ! last_error ))' last_error
}

function test_6()
{
  local last_error

  case "$OSTYPE" in
    cygwin* | msys* | mingw*)
      shopt -s nocasematch
    ;;
  esac

  tkl_normalize_path 'b/..'
  last_error=$?
  tkl_test_assert_true '[[ "$RETURN_VALUE" == "." ]]' RETURN_VALUE
  tkl_test_assert_true '(( ! last_error ))' last_error

  tkl_normalize_path 'b/..' -a
  last_error=$?
  tkl_test_assert_true '[[ "$RETURN_VALUE" == "$CWD" ]]' RETURN_VALUE CWD
  tkl_test_assert_true '(( ! last_error ))' last_error

  tkl_normalize_path 'b\..'
  last_error=$?
  tkl_test_assert_true '[[ "$RETURN_VALUE" == "." ]]' RETURN_VALUE
  tkl_test_assert_true '(( ! last_error ))' last_error

  tkl_normalize_path 'b\..' -a
  last_error=$?
  tkl_test_assert_true '[[ "$RETURN_VALUE" == "$CWD" ]]' RETURN_VALUE CWD
  tkl_test_assert_true '(( ! last_error ))' last_error
}

function test_7()
{
  local last_error

  case "$OSTYPE" in
    cygwin* | msys* | mingw*)
      shopt -s nocasematch
    ;;
  esac

  tkl_normalize_path 'b/.'
  last_error=$?
  tkl_test_assert_true '[[ "$RETURN_VALUE" == "b" ]]' RETURN_VALUE
  tkl_test_assert_true '(( ! last_error ))' last_error

  tkl_normalize_path 'b/.' -a
  last_error=$?
  tkl_test_assert_true '[[ "$RETURN_VALUE" == "$CWD/b" ]]' RETURN_VALUE CWD
  tkl_test_assert_true '(( ! last_error ))' last_error

  tkl_normalize_path 'b\.'
  last_error=$?
  tkl_test_assert_true '[[ "$RETURN_VALUE" == "b" ]]' RETURN_VALUE
  tkl_test_assert_true '(( ! last_error ))' last_error

  tkl_normalize_path 'b\.' -a
  last_error=$?
  tkl_test_assert_true '[[ "$RETURN_VALUE" == "$CWD/b" ]]' RETURN_VALUE CWD
  tkl_test_assert_true '(( ! last_error ))' last_error
}

function test_8()
{
  local last_error

  case "$OSTYPE" in
    cygwin* | msys* | mingw*)
      shopt -s nocasematch
    ;;
  esac

  tkl_normalize_path 'b/./..'
  last_error=$?
  tkl_test_assert_true '[[ "$RETURN_VALUE" == "." ]]' RETURN_VALUE
  tkl_test_assert_true '(( ! last_error ))' last_error

  tkl_normalize_path 'b/./..' -a
  last_error=$?
  tkl_test_assert_true '[[ "$RETURN_VALUE" == "$CWD" ]]' RETURN_VALUE CWD
  tkl_test_assert_true '(( ! last_error ))' last_error

  tkl_normalize_path 'b\.\..'
  last_error=$?
  tkl_test_assert_true '[[ "$RETURN_VALUE" == "." ]]' RETURN_VALUE
  tkl_test_assert_true '(( ! last_error ))' last_error

  tkl_normalize_path 'b\.\..' -a
  last_error=$?
  tkl_test_assert_true '[[ "$RETURN_VALUE" == "$CWD" ]]' RETURN_VALUE CWD
  tkl_test_assert_true '(( ! last_error ))' last_error
}

if [[ -z "$BASH_LINENO" || BASH_LINENO[0] -eq 0 ]]; then
  # Script was not included, then execute it.

  tkl_testmodule_init

  tkl_testmodule_run_test test_1
  tkl_testmodule_run_test test_2
  tkl_testmodule_run_test test_3
  tkl_testmodule_run_test test_4
  tkl_testmodule_run_test test_5
  tkl_testmodule_run_test test_6
  tkl_testmodule_run_test test_7
  tkl_testmodule_run_test test_8
fi

fi
