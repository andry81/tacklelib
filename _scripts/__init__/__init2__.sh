#!/bin/bash

# CAUTION:
#  In case of usage the QtCreator there is set of special broken cases you have to avoid:
#  1. Invalid characters in paths: `(`, `)` and `.`.
#  2. Non english locale in paths.

# Script can be ONLY included by "source" command.
if [[ -n "$BASH" && (-z "$BASH_LINENO" || BASH_LINENO[0] -gt 0) && (-z "$SOURCE_ROOT_INIT2_SH" || SOURCE_ROOT_INIT2_SH -eq 0) ]]; then 

SOURCE_ROOT_INIT2_SH=1 # including guard

tkl_include "__init1__.sh" || return $?

MakeOutputDirectories "$CMAKE_BUILD_TYPE" || return $?

fi
