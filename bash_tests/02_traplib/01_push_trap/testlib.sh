#!/bin/bash

# Script can be ONLY included by "source" command.
if [[ -n "$BASH" && (-z "$BASH_LINENO" || BASH_LINENO[0] -gt 0) ]]; then

tkl_include '../../__init__.sh' || tkl_abort_include
tkl_include "$PROJECT_ROOT/testlib.sh" || tkl_abort_include

function TestUserModuleInit()
{
  tkl_safe_func_call TestUserModuleInit_disabled_sigint
  TEST_SOURCES=("${TEST_SOURCES[@]}" "$PROJECT_ROOT/traplib.sh")
  TEST_FUNCTIONS=("${TEST_FUNCTIONS[@]}")
  TEST_VARIABLES=("${TEST_VARIABLES[@]}")
}

function TestUserModuleExit() { :; }

function TestUserInit() { :; }

function TestUserExit() { :; }

fi
