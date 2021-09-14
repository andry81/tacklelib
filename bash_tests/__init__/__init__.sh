#!/bin/bash

# Script can be ONLY included by "source" command.
[[ -z "$BASH" || (-n "$BASH_LINENO" && BASH_LINENO[0] -le 0) || (-n "$TACKLELIB_BASH_TESTS_ROOT_INIT0_DIR" && -d "$TACKLELIB_BASH_TESTS_ROOT_INIT0_DIR") ]] && return

tkl_include "../../__init__/__init__.sh" "$@" || tkl_abort_include

tkl_export_path TACKLELIB_BASH_TESTS_ROOT_INIT0_DIR "$BASH_SOURCE_DIR" # including guard

[[ -z "$TESTS_PROJECT_ROOT" ]] &&               tkl_export_path -a -s TESTS_PROJECT_ROOT                "$BASH_SOURCE_DIR/.."
[[ -z "$TESTS_PROJECT_INPUT_CONFIG_ROOT" ]] &&  tkl_export_path -a -s TESTS_PROJECT_INPUT_CONFIG_ROOT   "$TESTS_PROJECT_ROOT/_config"
[[ -z "$TESTS_PROJECT_OUTPUT_CONFIG_ROOT" ]] && tkl_export_path -a -s TESTS_PROJECT_OUTPUT_CONFIG_ROOT  "$TACKLELIB_PROJECT_OUTPUT_CONFIG_ROOT/bash_tests"

[[ ! -e "$TESTS_PROJECT_OUTPUT_CONFIG_ROOT" ]] && { mkdir -p "$TESTS_PROJECT_OUTPUT_CONFIG_ROOT" || tkl_abort 10; }

: # resets exit code to 0
