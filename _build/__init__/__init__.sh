#!/bin/bash

# Script can be ONLY included by "source" command.
[[ -n "$BASH" && (-z "$BASH_LINENO" || BASH_LINENO[0] -gt 0) && (-z "$TACKLELIB_PROJECT_BUILD_ROOT_INIT0_DIR" || "$TACKLELIB_PROJECT_BUILD_ROOT_INIT0_DIR" != "$TACKLELIB_PROJECT_BUILD_ROOT") ]] || return 0 || exit 0 # exit to avoid continue if the return can not be called

tkl_include_or_abort "../../__init__/__init__.sh"

tkl_export_path TACKLELIB_PROJECT_BUILD_ROOT_INIT0_DIR "$BASH_SOURCE_DIR" # including guard

tkl_include_or_abort "$TACKLELIB_PROJECT_BUILD_ROOT/tools/projectlib.sh"

: # resets exit code to 0
