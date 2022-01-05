#!/bin/bash

# Script ONLY for execution.
if [[ -n "$BASH" && (-z "$BASH_LINENO" || ${BASH_LINENO[0]} -eq 0) ]]; then

if [[ -z "$SOURCE_TACKLELIB_BASH_TACKLELIB_SH" || SOURCE_TACKLELIB_BASH_TACKLELIB_SH -eq 0 ]]; then
  # builtin search
  for BASH_SOURCE_DIR in "/usr/local/bin" "/usr/bin" "/bin"; do
    [[ -f "$BASH_SOURCE_DIR/bash_tacklelib" ]] && {
      source "$BASH_SOURCE_DIR/bash_tacklelib" || exit $?
      break
    }
  done
fi

tkl_include_or_abort '../__init__/__init__.sh'

USER="${1:-$USER}"
GROUP="${2:-$USER}"

if [[ -z "${USER}" ]]; then
  echo "$BASH_SOURCE_FILE_NAME: error: USER argument is not set." >&2
  tkl_exit 255
fi

if [[ -z "${GROUP}" ]]; then
  echo "$BASH_SOURCE_FILE_NAME: error: GROUP argument is not set." >&2
  tkl_exit 255
fi

echo "Updating permissions for user=\"$USER\" and group=\"$GROUP\"..."

tkl_call sudo chown -R ${USER}:${GROUP} "${TACKLELIB_PROJECT_ROOT}"
tkl_call sudo chmod -R ug+rw "${TACKLELIB_PROJECT_ROOT}"

IFS=$' \t\r\n'; for file in `find "${TACKLELIB_PROJECT_ROOT}" -type f -name "*.sh"`; do
  tkl_call sudo chmod ug+x "$file"
done

echo "Done."

tkl_exit

fi
