#!/bin/bash

# Script can be ONLY included by "source" command.
[[ -n "$BASH" && (-z "$BASH_LINENO" || BASH_LINENO[0] -gt 0) ]] || return 0 || exit 0 # exit to avoid continue if the return can not be called

tkl_include_or_abort "$TACKLELIB_BASH_ROOT/tacklelib/testlib.sh"

function TestUserModuleInit()
{
  local cwd="$TACKLELIB_BASH_TESTS_PROJECT_ROOT/unit/03_load_config"

  TEST_SOURCES=(
    "$TACKLELIB_BASH_ROOT/tacklelib/tools/load_config.sh"
  )

  TEST_FUNCTIONS=(
    test_load_config
  )

  TEST_VARIABLES=(
    CWD                     "$cwd"
    TEST_DATA_DIR           "$cwd/_testdata"
    LOAD_CONFIG_BARE_FLAGS  ''
  )

  tkl_pushd "$cwd"
}

function TestUserModuleExit() { :; }

function TestUserInit()
{
  tkl_convert_native_path_to_backend "$CWD"
  CWD="$RETURN_VALUE"
}

function TestUserExit() { :; }

function test_load_config()
{
  local config_file="$1"
  local test_var_name_prefix="$2"
  local reference_var_name_prefix="$3"
  shift 3
  local test_var_name_suffix_arr=("$@")

  tkl_call tkl_test_assert_true_expr tkl_load_config${LOAD_CONFIG_BARE_FLAGS:+ }$LOAD_CONFIG_BARE_FLAGS -- "$TEST_DATA_DIR" "$TEST_DATA_DIR" "$config_file" "$PARAM0" "$PARAM1"

  local arg
  for arg in "${test_var_name_suffix_arr[@]}"; do
    tkl_test_assert_true "[[ \"\$$test_var_name_prefix$arg\" == \"\$$reference_var_name_prefix$arg\" ]]" "$test_var_name_prefix$arg" "$reference_var_name_prefix$arg"
  done
}
