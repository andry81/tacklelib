#!/bin/bash

# Script can be ONLY included by "source" command.
[[ -n "$BASH" && (-z "$BASH_LINENO" || BASH_LINENO[0] -gt 0) && (-z "$TACKLELIB_BASH_TESTS_PROJECT_ROOT_INIT0_DIR" || "$TACKLELIB_BASH_TESTS_PROJECT_ROOT_INIT0_DIR" != "$TACKLELIB_BASH_TESTS_PROJECT_ROOT") ]] || return 0 || exit 0 # exit to avoid continue if the return can not be called

tkl_include_or_abort "../../__init__/__init__.sh" "$@"

[[ -n "$TACKLELIB_BASH_TESTS_PROJECT_ROOT" ]] ||                tkl_export_path -a -s TACKLELIB_BASH_TESTS_PROJECT_ROOT                 "$BASH_SOURCE_DIR/.."
[[ -n "$TACKLELIB_BASH_TESTS_PROJECT_INPUT_CONFIG_ROOT" ]] ||   tkl_export_path -a -s TACKLELIB_BASH_TESTS_PROJECT_INPUT_CONFIG_ROOT    "$TACKLELIB_BASH_TESTS_PROJECT_ROOT/_config"
[[ -n "$TACKLELIB_BASH_TESTS_PROJECT_OUTPUT_CONFIG_ROOT" ]] ||  tkl_export_path -a -s TACKLELIB_BASH_TESTS_PROJECT_OUTPUT_CONFIG_ROOT   "$TACKLELIB_PROJECT_OUTPUT_CONFIG_ROOT/bash_tests"

[[ -e "$TACKLELIB_BASH_TESTS_PROJECT_OUTPUT_CONFIG_ROOT" ]] || mkdir -p "$TACKLELIB_BASH_TESTS_PROJECT_OUTPUT_CONFIG_ROOT" || tkl_abort

tkl_export_path TACKLELIB_BASH_TESTS_PROJECT_ROOT_INIT0_DIR "$TACKLELIB_BASH_TESTS_PROJECT_ROOT" # including guard

: # resets exit code to 0
