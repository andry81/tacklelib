#!/bin/bash

# Script ONLY for execution.
if [[ -n "$BASH" && (-z "$BASH_LINENO" || ${BASH_LINENO[0]} -eq 0) ]]; then 

function ScriptBaseInit()
{
  if [[ -n "$BASH_LINENO" ]] && (( ${BASH_LINENO[${#BASH_LINENO[@]}-1]} > 0 )); then
    local ScriptFilePath="${BASH_SOURCE[${#BASH_LINENO[@]}-1]//\\//}"
  else
    local ScriptFilePath="${0//\\//}"
  fi

  GetAbsolutePathFromDirPath "$ScriptFilePath"
  ScriptFilePath="${RETURN_VALUE}"

  local ScriptDirPath="${ScriptFilePath%[/]*}"
  local ScriptFileName="${ScriptFilePath##*[/]}"

  return_local ScriptFilePath "${ScriptFilePath}"
  return_local ScriptDirPath "${ScriptDirPath}"
  return_local ScriptFileName "${ScriptFileName}"
}

# WORKAROUND:
#   The `declare -g` has been introduced in the `bash-4.2-alpha`, so to make
#   a global variable in an older version we have to replace the
#   `declare -g` by a sequence of calls to `unset` and `eval`.
#
#   The `return_local` has used for both issues:
#   1. To return a local variable.
#   2. To replace the `declare -g`.
#
function return_local()
{
  unset $1 # must be local
  eval "$1=\"\$2\""
}

function GetAbsolutePathFromDirPath()
{
  # drop return value
  RETURN_VALUE="$1"

  local DirPath="$1"
  local RelativePath="$2"

  # WORKAROUND:
  #   Because some versions of readlink can not handle windows native absolute
  #   paths correctly, then always try to convert directory path to a backend
  #   path before the readlink in case if the path has specific native path
  #   characters.
  if [[ "${DirPath:1:1}" == ":" ]]; then
    ConvertNativePathToBackend "$DirPath"
    DirPath="$RETURN_VALUE"
  fi

  if [[ -n "$DirPath" && -x "/bin/readlink" ]]; then
    if [[ "${RelativePath:0:1}" != '/' ]]; then
      RETURN_VALUE="`/bin/readlink -m "$DirPath${RelativePath:+/}$RelativePath"`"
    else
      RETURN_VALUE="`/bin/readlink -m "$RelativePath"`"
    fi
  fi

  return 0
}

function ConvertNativePathToBackend()
{
  # drop return value
  RETURN_VALUE="$1"

  # Convert all back slashes to slashes.
  local PathToConvert="${1//\\//}"

  [[ -n "$PathToConvert" ]] || return 1

  # workaround for the bash 3.1.0 bug for the expression "${arg:X:Y}",
  # where "Y == 0" or "Y + X >= ${#arg}"
  local PathToConvertLen=${#PathToConvert}
  local PathPrefixes=('' '')
  local PathSuffix=""
  if (( PathToConvertLen > 0 )); then
    PathPrefixes[0]="${PathToConvert:0:1}"
  fi
  if (( PathToConvertLen > 1 )); then
    PathPrefixes[1]="${PathToConvert:1:1}"
  fi
  if (( PathToConvertLen >= 3 )); then
    PathSuffix="${PathToConvert:2}"
  fi
  PathSuffix="${PathSuffix%/}"

  # Convert path drive prefix too.
  if [[ "${PathPrefixes[0]}" != '/' && "${PathPrefixes[0]}" != '.' && "${PathPrefixes[1]}" == ':' ]]; then
    case "$OSTYPE" in
      "cygwin") PathToConvert="/cygdrive/${PathPrefixes[0]}$PathSuffix" ;;
      *)
        PathToConvert="/${PathPrefixes[0]}$PathSuffix"
        # add slash to the end of path in case of drive only path
        (( ! ${#PathSuffix} )) && PathToConvert="$PathToConvert/"
      ;;
    esac
  fi

  RETURN_VALUE="$PathToConvert"

  return 0
}

ScriptBaseInit "$@"

if [[ ! -f "$ScriptDirPath/user_links.lst" ]]; then
  echo "$ScriptFileName: error: \"user_links.lst\" must exist in the script directory: \"$ScriptDirPath/\"" >&2
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
