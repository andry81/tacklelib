#!/bin/bash

if [[ -z "$SOURCE_TACKLELIB_BASH_TACKLELIB_SH" || SOURCE_TACKLELIB_BASH_TACKLELIB_SH -eq 0 ]]; then
  # builtin search
  for BASH_SOURCE_DIR in '/usr/local/bin' '/usr/bin' '/bin'; do
    if [[ -f "$BASH_SOURCE_DIR/bash_tacklelib" ]]; then
      source "$BASH_SOURCE_DIR/bash_tacklelib" || exit $?
      break
    fi
  done
fi

case "$OSTYPE" in
  cygwin* | msys* | mingw*)
    PYTHON_EXE_PATH='c:/Python/x86/38/python.exe'
    TERMINAL_CMD=('cmd.exe' /c start '')
  ;;
  *)
    PYTHON_EXE_PATH='python3'
    TERMINAL_CMD=('konsole' --separate --noclose -e)
  ;;
esac 

if [[ ! -x "$PYTHON_EXE_PATH" ]] && ! which "$PYTHON_EXE_PATH" >/dev/null 2>&1; then
  echo "$0: error: \`$PYTHON_EXE_PATH\` is not found." >&2
  exit 255
fi
if (( ${#TERMINAL_CMD[@]} )) && [[ ! -x "${TERMINAL_CMD[0]}" ]] && ! which "${TERMINAL_CMD[0]}" >/dev/null 2>&1; then
  echo "$0: error: terminal \`${TERMINAL_CMD[0]}\` is not known to run multiple processes in background." >&2
  exit 254
fi

export TACKLELIB_ROOT="$BASH_SOURCE_DIR/../../../python/tacklelib"
export CMDOPLIB_ROOT="$BASH_SOURCE_DIR/../../../python/cmdoplib"
export PYTHONDONTWRITEBYTECODE=1

"${TERMINAL_CMD[@]}" "$PYTHON_EXE_PATH" "$BASH_SOURCE_DIR/test_fcache.xpy" 111 &
"${TERMINAL_CMD[@]}" "$PYTHON_EXE_PATH" "$BASH_SOURCE_DIR/test_fcache.xpy" 222 &
"${TERMINAL_CMD[@]}" "$PYTHON_EXE_PATH" "$BASH_SOURCE_DIR/test_fcache.xpy" 333 &
"${TERMINAL_CMD[@]}" "$PYTHON_EXE_PATH" "$BASH_SOURCE_DIR/test_fcache.xpy" 444 &
"${TERMINAL_CMD[@]}" "$PYTHON_EXE_PATH" "$BASH_SOURCE_DIR/test_fcache.xpy" 555 &
