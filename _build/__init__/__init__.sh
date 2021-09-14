#!/bin/bash

# Script can be ONLY included by "source" command.
[[ -z "$BASH" || (-n "$BASH_LINENO" && BASH_LINENO[0] -le 0) || (-n "$TACKLELIB_PROJECT_BUILD_ROOT_INIT0_DIR" && -d "$TACKLELIB_PROJECT_BUILD_ROOT_INIT0_DIR") ]] && return

tkl_include "../../__init__/__init__.sh" "$@" || tkl_abort_include

tkl_export_path TACKLELIB_PROJECT_BUILD_ROOT_INIT0_DIR "$BASH_SOURCE_DIR" # including guard

tkl_include "$TACKLELIB_PROJECT_BUILD_ROOT/tools/projectlib.sh" || tkl_abort_include

: # resets exit code to 0
