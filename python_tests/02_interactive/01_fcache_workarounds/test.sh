#!/bin/bash

source "/bin/bash_entry" || exit

tkl_make_source_file_components

PYTHON_EXE_PATH=python3
TERMINAL_CMD="konsole --separate --noclose -e"
export TACKLELIB_ROOT="$BASH_SOURCE_DIR/../../../python/tacklelib"
export CMDOPLIB_ROOT="$BASH_SOURCE_DIR/../../../python/cmdoplib"
export PYTHONDONTWRITEBYTECODE=1

$TERMINAL_CMD "$PYTHON_EXE_PATH" "$BASH_SOURCE_DIR/test_fcache.xpy" 111 &
$TERMINAL_CMD "$PYTHON_EXE_PATH" "$BASH_SOURCE_DIR/test_fcache.xpy" 222 &
$TERMINAL_CMD "$PYTHON_EXE_PATH" "$BASH_SOURCE_DIR/test_fcache.xpy" 333 &
$TERMINAL_CMD "$PYTHON_EXE_PATH" "$BASH_SOURCE_DIR/test_fcache.xpy" 444 &
$TERMINAL_CMD "$PYTHON_EXE_PATH" "$BASH_SOURCE_DIR/test_fcache.xpy" 555 &
