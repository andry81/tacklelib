#!/bin/bash

# Script can be ONLY included by "source" command.
if [[ -n "$BASH" && (-z "$BASH_LINENO" || BASH_LINENO[0] -gt 0) && "$TACKLELIB_SCRIPTS_INIT2_DIR" != "$BASH_SOURCE_DIR" ]]; then 

function __init2__()
{
  tkl_include '__init1__.sh' || tkl_abort_include

  tkl_declare_global TACKLELIB_SCRIPTS_INIT2_DIR "$BASH_SOURCE_DIR" # including guard

  MakeOutputDirectories "$CMAKE_BUILD_TYPE" "$GENERATOR_IS_MULTI_CONFIG" || tkl_abort_include
}

__init2__

fi
