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

tkl_include '../__init__/__init__.sh' || tkl_abort_include

APP_ROOT="`readlink -f "$BASH_SOURCE_DIR/../.."`"
APP_DIR_LIST=("$APP_ROOT" "$APP_ROOT/lib")

CONFIGURE_ROOT="$1"
OUT_GEN_DIR="${2:-$BASH_SOURCE_DIR}"  # directory there to save generated file

if [[ -n "$CONFIGURE_ROOT" ]]; then
  if [[ -d "$CONFIGURE_ROOT" ]]; then
    CONFIGURE_ROOT="`readlink -f "$CONFIGURE_ROOT"`"
    APP_DIR_LIST=("$CONFIGURE_ROOT" "$CONFIGURE_ROOT/lib")
  else
    echo "$BASH_SOURCE_FILE_NAME: error: input directory is not found: \"$CONFIGURE_ROOT\"."
    exit 2
  fi
fi

if [[ ! -d "$OUT_GEN_DIR" ]]; then
  echo "$BASH_SOURCE_FILE_NAME: error: directory OUT_GEN_DIR is not found: \"$OUT_GEN_DIR\"." >&2
  exit 3
fi

function GetFileDir()
{
  local file_in="$1"

  if [[ -n "$file_in" ]]; then
    RETURN_VALUE="${file_in%/*}"
    [[ -z "$RETURN_VALUE" ]] && RETURN_VALUE="/"
  else
    RETURN_VALUE="."
  fi
}

function GetFileName()
{
  local file_in="$1"

  RETURN_VALUE="${file_in##*/}"
}

echo -n "" > "$OUT_GEN_DIR/gen_links.lst"

# generated links from application directory list
for app_dir in "${APP_DIR_LIST[@]}"; do
  [[ ! -d "$app_dir" ]] && continue
  pushd "$app_dir" > /dev/null && {
    IFS=$' \t\r\n'; for link_file in `find "$app_dir" -maxdepth 1 -type l -name "*"`; do
      file="`readlink -f "$link_file"`"

      GetFileName "$link_file"
      link_file_name="$RETURN_VALUE"

      GetFileDir "$file"
      file_dir="$RETURN_VALUE"

      GetFileName "$file"
      file_name="$RETURN_VALUE"

      if [[ "$app_dir" == "$file_dir" ]]; then
        echo "  '$link_file_name' -> '$file_name'"
        echo "$link_file_name $file_name" >> "$OUT_GEN_DIR/gen_links.lst"
      else
        echo "  '$link_file_name' -> '$file'"
        echo "$link_file_name $file" >> "$OUT_GEN_DIR/gen_links.lst"
      fi
    done
    popd > /dev/null
  }
done

echo "Done."
echo

exit 0

fi
