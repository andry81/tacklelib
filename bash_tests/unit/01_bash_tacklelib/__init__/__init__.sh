#!/bin/bash

# Script can be ONLY included by "source" command.
[[ -z "$BASH" || (-n "$BASH_LINENO" && BASH_LINENO[0] -le 0) || (-n "$TACKLELIB_BASH_TESTS_ROOT_INIT0_DIR" && -d "$TACKLELIB_BASH_TESTS_ROOT_INIT0_DIR") ]] && return

tkl_include_or_abort "../../__init__/__init__.sh" "$@"
