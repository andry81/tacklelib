#!/bin/bash

# Script can be ONLY included by "source" command.
[[ -z "$BASH" || (-n "$BASH_LINENO" && BASH_LINENO[0] -le 0) ]] && return

source '/bin/bash_tacklelib' || exit $?
tkl_include '__init__.sh' || tkl_abort_include
tkl_include "$TACKLELIB_BASH_ROOT/tacklelib/testlib.sh" || tkl_abort_include

function TestUserModuleInit()
{
  tkl_safe_func_call TestUserModuleInit_disabled_sigint
  TEST_SOURCES=("${TEST_SOURCES[@]}" "$TACKLELIB_BASH_ROOT/tacklelib/traplib.sh")
  TEST_FUNCTIONS=("${TEST_FUNCTIONS[@]}")
  TEST_VARIABLES=("${TEST_VARIABLES[@]}")
}

function TestUserModuleExit() { :; }

function TestUserInit() { :; }

function TestUserExit() { :; }
