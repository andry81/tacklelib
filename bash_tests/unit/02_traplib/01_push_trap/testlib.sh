#!/bin/bash

# Script can be ONLY included by "source" command.
[[ -n "$BASH" && (-z "$BASH_LINENO" || BASH_LINENO[0] -gt 0) ]] || return 0 || exit 0 # exit to avoid continue if the return can not be called

tkl_include_or_abort "$TACKLELIB_BASH_ROOT/tacklelib/testlib.sh"

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
