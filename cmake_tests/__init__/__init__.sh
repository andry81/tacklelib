#!/bin/bash

# Script can be ONLY included by "source" command.
[[ -n "$BASH" && (-z "$BASH_LINENO" || BASH_LINENO[0] -gt 0) && (-z "$TACKLELIB_CMAKE_TESTS_ROOT_INIT0_DIR" || "$TACKLELIB_CMAKE_TESTS_ROOT_INIT0_DIR" != "$TACKLELIB_CMAKE_TESTS_ROOT") ]] || return 0 || exit 0 # exit to avoid continue if the return can not be called

tkl_include_or_abort "../../__init__/__init__.sh"

tkl_export_path TACKLELIB_CMAKE_TESTS_ROOT_INIT0_DIR "$BASH_SOURCE_DIR" # including guard

[[ -z "$TESTS_PROJECT_ROOT" ]] &&               tkl_export_path -a -s TESTS_PROJECT_ROOT                "$BASH_SOURCE_DIR/.."
[[ -z "$TESTS_PROJECT_INPUT_CONFIG_ROOT" ]] &&  tkl_export_path -a -s TESTS_PROJECT_INPUT_CONFIG_ROOT   "$TESTS_PROJECT_ROOT/_config"
[[ -z "$TESTS_PROJECT_OUTPUT_CONFIG_ROOT" ]] && tkl_export_path -a -s TESTS_PROJECT_OUTPUT_CONFIG_ROOT  "$TACKLELIB_PROJECT_OUTPUT_CONFIG_ROOT/cmake_tests"

[[ ! -e "$TESTS_PROJECT_OUTPUT_CONFIG_ROOT" ]] && { mkdir -p "$TESTS_PROJECT_OUTPUT_CONFIG_ROOT" || tkl_abort 10; }

tkl_load_config_dir "$TESTS_PROJECT_INPUT_CONFIG_ROOT" "$TESTS_PROJECT_OUTPUT_CONFIG_ROOT"

: # resets exit code to 0
