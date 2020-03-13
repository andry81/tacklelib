#!/bin/bash

# Script can be ONLY included by "source" command.
if [[ -n "$BASH" && (-z "$BASH_LINENO" || BASH_LINENO[0] -gt 0) ]]; then

tkl_include '../../__init__.sh' || exit $?
tkl_include "$PROJECT_ROOT/traplib.sh" || exit $?

function TestUserModuleInit()
{
  TEST_SOURCES=('baselib.sh' 'testlib.sh')
  TEST_FUNCTIONS=()
}

function TestUserInit() { :; }

function TestUserModuleExit() { :; }

function TestUserExit() { :; }

fi
