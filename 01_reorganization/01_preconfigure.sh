#!/bin/bash

# Script ONLY for execution.
if [[ -n "$BASH" && (-z "$BASH_LINENO" || BASH_LINENO[0] -eq 0) ]]; then

source "/bin/bash_entry" || exit $?
tkl_include "__init__.sh" || exit $?

function Call()
{
  echo ">$@"
  echo
  tkl_exec_inproc "$@"
  LastError=$?
  return $LastError
}

function Pause()
{
  local key
  read -n1 -r -p "Press any key to continue..." key
  echo
}

case "$OSTYPE" in
  mingw* | msys* | cygwin*)
    Call "${COMSPEC//\\//}" /c "$TACKLELIB_PROJECT_ROOT/01_preconfigure.bat" $@
    exit $?
    ;;
  *)
    echo "1. Download the local third party project: `tacklelib--3dparty`: https://sf.net/p/tacklelib/3dparty"
    echo "2. Read the instructions from the readme file in the downloaded project to checkout third party sources."
    echo "3. Press any key to continue and select the `_src` subdirectory in the `tacklelib--3dparty` project as a third party catalog."

    Pause

    TACKLELIB_3DPARTY_ROOT=$("$CONTOOLS_UTILITIES_BIN_ROOT/wxFileDialog" "" "$TACKLELIB_PROJECT_ROOT" "Select the third party catalog to link with..." -de)

    if [[ ! -d "$TACKLELIB_3DPARTY_ROOT" ]]; then
      if [[ -z "$TACKLELIB_3DPARTY_ROOT" ]]; then
        echo "error: $0: third party catalog is not selected." >&2
      else
        echo "error: $0: third party catalog does not exist: `$TACKLELIB_3DPARTY_ROOT`" >&2
      fi
      exit 255
    fi

    Call ln -s "$TACKLELIB_PROJECT_ROOT/_3dparty" "$TACKLELIB_3DPARTY_ROOT"

    #Call ln -s "$TACKLELIB_PROJECT_ROOT/_3dparty/utility/tacklelib/tacklelib/_scripts" "$TACKLELIB_PROJECT_ROOT/_scripts"
    #Call ln -s "$TACKLELIB_PROJECT_ROOT/_3dparty/utility/tacklelib/tacklelib/cmake" "$TACKLELIB_PROJECT_ROOT/cmake"
    ;;
esac

fi
