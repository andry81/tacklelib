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

if [[ ! -f "$BASH_SOURCE_DIR/user_links.lst" ]]; then
  echo "$BASH_SOURCE_FILE_NAME: error: \"user_links.lst\" must exist in the script directory: \"$BASH_SOURCE_DIR/\"" >&2
  exit 1
fi

flag_args=()

tkl_read_command_line_flags flag_args "$@"
(( ${#flag_args[@]} )) && shift ${#flag_args[@]}

APP_ROOT="`readlink -f "$BASH_SOURCE_DIR/../.."`"
APP_DIR_LIST=("$APP_ROOT" "$APP_ROOT/lib")

CONFIGURE_ROOT="$1"

if [[ -n "$CONFIGURE_ROOT" ]]; then
  if [[ -d "$CONFIGURE_ROOT" ]]; then
    CONFIGURE_ROOT="`readlink -f "$CONFIGURE_ROOT"`"
    APP_DIR_LIST=("$CONFIGURE_ROOT" "$CONFIGURE_ROOT/lib")
  else
    echo "$BASH_SOURCE_FILE_NAME: error: input directory is not found: \"$CONFIGURE_ROOT\"."
    exit 2
  fi
fi

create_user_symlinks_only=0

for flag in "${flag_args[@]}"; do
  if [[ "${flag//u/}" != "$flag" ]]; then
    create_user_symlinks_only=1
    break
  fi
done

if (( ! create_user_symlinks_only )) && [[ ! -f "$BASH_SOURCE_DIR/gen_links.lst" ]]; then
  echo "$BASH_SOURCE_FILE_NAME: error: \"gen_links.lst\" must exist in the script directory." >&2
  exit 3
fi

# create user links at first
echo "Creating user links from \"$BASH_SOURCE_DIR/user_links.lst\"..."
num_links=0
for app_dir in "${APP_DIR_LIST[@]}"; do
  [[ ! -d "$app_dir" ]] && continue
  pushd "$app_dir" > /dev/null && {
    while IFS=$' \t\r\n' read -r LinkPath RefPath; do
      LinkPath="${LinkPath%%[#]*}" # cut off comments
      if [[ -n "${LinkPath//[[:space:]]/}" && -f "$RefPath" ]]; then
        echo "  '$LinkPath' -> '$RefPath'"
        ln -s "$RefPath" "$LinkPath"
        (( num_links++ ))
      fi
    done < "$BASH_SOURCE_DIR/user_links.lst"
    popd > /dev/null
  }
done

(( num_links )) && echo

if (( ! create_user_symlinks_only )); then
  # create generated links
  echo "Creating generated links from \"$BASH_SOURCE_DIR/gen_links.lst\"..."
  for app_dir in "${APP_DIR_LIST[@]}"; do
    [[ ! -d "$app_dir" ]] && continue
    pushd "$app_dir" > /dev/null && {
      while read -r LinkPath RefPath; do
        if [[ -n "$LinkPath" && -f "$RefPath" ]]; then
          echo "  '$LinkPath' -> '$RefPath'"
          ln -s "$RefPath" "$LinkPath"
        fi
      done < "$BASH_SOURCE_DIR/gen_links.lst"
      popd > /dev/null
    }
  done
  echo
fi

echo "Done."
echo

exit 0

fi
