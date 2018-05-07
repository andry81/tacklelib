#!/bin/bash

# Script ONLY for execution.
if [[ -n "$BASH" && (-z "$BASH_LINENO" || ${BASH_LINENO[0]} -eq 0) ]]; then 

if [[ "$(type -t ScriptBaseInit)" != "function" ]]; then
  function ScriptBaseInit
  {
    if [[ -n "$BASH_LINENO" ]] && (( ${BASH_LINENO[0]} > 0 )); then
      ScriptFilePath="${BASH_SOURCE[0]//\\//}"
    else
      ScriptFilePath="${0//\\//}"
    fi
    if [[ "${ScriptFilePath:1:1}" == ":" ]]; then
      ScriptFilePath="`/bin/readlink -f "/${ScriptFilePath/:/}"`"
    else
      ScriptFilePath="`/bin/readlink -f "$ScriptFilePath"`"
    fi

    ScriptDirPath="${ScriptFilePath%[/]*}"
    ScriptFileName="${ScriptFilePath##*[/]}"
  }

  ScriptBaseInit "$@"
fi

if [[ ! -f "$ScriptDirPath/user_links.lst" ]]; then
  echo "$ScriptFileName: error: \"user_links.lst\" must exist in the script directory" >&2
  exit 1
fi

function ReadCommandLineFlags()
{
  local out_args_list_name_var="$1"
  shift

  local args
  args=("$@")
  local args_len=${#@}

  local i
  local j

  j=0
  for (( i=0; i < $args_len; i++ )); do
    # collect all flag arguments until first not flag
    if (( ${#args[i]} )); then
      if [[ "${args[i]#-}" != "${args[i]}" ]]; then
        eval "$out_args_list_name_var[j++]=\"\${args[i]}\""
        shift
      else
        break
      fi
    else
      # stop on empty string too
      break
    fi
  done
}

flag_args=()

ReadCommandLineFlags flag_args "$@"
(( ${#flag_args[@]} )) && shift ${#flag_args[@]}

APP_ROOT="`readlink -f "$ScriptDirPath/../.."`"
APP_DIR_LIST=("$APP_ROOT" "$APP_ROOT/lib")

CONFIGURE_ROOT="$1"

if [[ -n "$CONFIGURE_ROOT" ]]; then
  if [[ -d "$CONFIGURE_ROOT" ]]; then
    CONFIGURE_ROOT="`readlink -f "$CONFIGURE_ROOT"`"
    APP_DIR_LIST=("$CONFIGURE_ROOT" "$CONFIGURE_ROOT/lib")
  else
    echo "$ScriptFileName: error: input directory is not found: \"$CONFIGURE_ROOT\"."
    exit 2
  fi
fi

create_user_symlinks_only=0

IFS=$' \t\r\n'; for flag in "${flag_args[@]}"; do
  if [[ "${flag//u/}" != "$flag" ]]; then
    create_user_symlinks_only=1
    break
  fi
done

if (( ! create_user_symlinks_only )) && [[ ! -f "$ScriptDirPath/gen_links.lst" ]]; then
  echo "$ScriptFileName: error: \"gen_links.lst\" must exist in the script directory." >&2
  exit 3
fi

# create user links at first
echo "Creating user links from \"$ScriptDirPath/user_links.lst\"..."
num_links=0
IFS=$' \t\r\n'; for app_dir in "${APP_DIR_LIST[@]}"; do
  [[ ! -d "$app_dir" ]] && continue
  pushd "$app_dir" > /dev/null && {
    IFS=$' \t\r\n'; while read -r LinkPath RefPath; do
      LinkPath="${LinkPath%%[#]*}" # cut off comments
      if [[ -n "${LinkPath//[[:space:]]/}" && -f "$RefPath" ]]; then
        echo "  '$LinkPath' -> '$RefPath'"
        ln -s "$RefPath" "$LinkPath"
        (( num_links++ ))
      fi
    done < "$ScriptDirPath/user_links.lst"
    popd > /dev/null
  }
done

(( num_links )) && echo

if (( ! create_user_symlinks_only )); then
  # create generated links
  echo "Creating generated links from \"$ScriptDirPath/gen_links.lst\"..."
  IFS=$' \t\r\n'; for app_dir in "${APP_DIR_LIST[@]}"; do
    [[ ! -d "$app_dir" ]] && continue
    pushd "$app_dir" > /dev/null && {
      while read -r LinkPath RefPath; do
        if [[ -n "$LinkPath" && -f "$RefPath" ]]; then
          echo "  '$LinkPath' -> '$RefPath'"
          ln -s "$RefPath" "$LinkPath"
        fi
      done < "$ScriptDirPath/gen_links.lst"
      popd > /dev/null
    }
  done
  echo
fi

echo "Done."
echo

exit 0

fi
