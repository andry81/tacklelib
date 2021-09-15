#!/bin/bash

# Script ONLY for execution.
if [[ -n "$BASH" && (-z "$BASH_LINENO" || ${BASH_LINENO[0]} -eq 0) ]]; then

source '/bin/bash_tacklelib' || exit $?
tkl_include '../__init__/__init__.sh' || tkl_abort_include

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
