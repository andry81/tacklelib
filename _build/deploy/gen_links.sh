#!/bin/bash

# Script ONLY for execution.
if [[ -n "$BASH" && (-z "$BASH_LINENO" || ${BASH_LINENO[0]} -eq 0) ]]; then 

# WORKAROUND:
#   The `declare -g` has been introduced in the `bash-4.2-alpha`, so to make
#   a global variable in an older version we have to replace the
#   `declare -g` by a sequence of calls to `unset` and `eval`.
#
#   The `tkl_return_local` has used for both issues:
#   1. To return a local variable.
#   2. To replace the `declare -g`.
#
function tkl_return_local()
{
  unset $1 # must be local
  eval "$1=\"\$2\""
}

function ScriptBaseInit()
{
  if [[ -n "$BASH_LINENO" ]] && (( ${BASH_LINENO[${#BASH_LINENO[@]}-1]} > 0 )); then
    local ScriptFilePath="${BASH_SOURCE[${#BASH_LINENO[@]}-1]//\\//}"
  else
    local ScriptFilePath="${0//\\//}"
  fi

  tkl_get_abs_path_from_dir "$ScriptFilePath"
  ScriptFilePath="${RETURN_VALUE}"

  local ScriptDirPath="${ScriptFilePath%[/]*}"
  local ScriptFileName="${ScriptFilePath##*[/]}"

  tkl_return_local ScriptFilePath "${ScriptFilePath}"
  tkl_return_local ScriptDirPath "${ScriptDirPath}"
  tkl_return_local ScriptFileName "${ScriptFileName}"
}

function tkl_get_abs_path_from_dir()
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
    tkl_convert_native_path_to_backend "$DirPath"
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

function tkl_convert_native_path_to_backend()
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
      cygwin*) PathToConvert="/cygdrive/${PathPrefixes[0]}$PathSuffix" ;;
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

APP_ROOT="`readlink -f "$ScriptDirPath/../.."`"
APP_DIR_LIST=("$APP_ROOT" "$APP_ROOT/lib")

CONFIGURE_ROOT="$1"
OUT_GEN_DIR="${2:-$ScriptDirPath}"  # directory there to save generated file

if [[ -n "$CONFIGURE_ROOT" ]]; then
  if [[ -d "$CONFIGURE_ROOT" ]]; then
    CONFIGURE_ROOT="`readlink -f "$CONFIGURE_ROOT"`"
    APP_DIR_LIST=("$CONFIGURE_ROOT" "$CONFIGURE_ROOT/lib")
  else
    echo "$ScriptFileName: error: input directory is not found: \"$CONFIGURE_ROOT\"."
    exit 2
  fi
fi

if [[ ! -d "$OUT_GEN_DIR" ]]; then
  echo "$ScriptFileName: error: directory OUT_GEN_DIR is not found: \"$OUT_GEN_DIR\"." >&2
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
