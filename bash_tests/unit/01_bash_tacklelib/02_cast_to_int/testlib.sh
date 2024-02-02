#!/bin/bash

# Script can be ONLY included by "source" command.
[[ -n "$BASH" && (-z "$BASH_LINENO" || BASH_LINENO[0] -gt 0) ]] || return 0 || exit 0 # exit to avoid continue if the return can not be called

tkl_include_or_abort "$TACKLELIB_BASH_ROOT/tacklelib/testlib.sh"

function TestUserModuleInit()
{
  TEST_SOURCES=()
  TEST_FUNCTIONS=()
  TEST_VARIABLES=(
    _ ''
    __ ''
    a '+0'
    b '-1'
    c '-0+0'
    d '1/1'
    e '1/0'
    f '1a'
  )
}

function TestUserModuleExit() { :; }

function TestUserInit() { :; }

function TestUserExit() { :; }
