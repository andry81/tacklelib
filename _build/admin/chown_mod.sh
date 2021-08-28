#!/bin/bash

# Script ONLY for execution.
if [[ -n "$BASH" && (-z "$BASH_LINENO" || ${BASH_LINENO[0]} -eq 0) ]]; then 

# WORKAROUND:
#   The `declare -g` has been introduced in the `bash-4.2-alpha`, so to make
#   a global variable in an older version we have to replace the
#   `declare -g` by a sequence of calls to `unset` and `eval`.
#
#   The `return_local` has used for both issues:
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

USER="${1:-$USER}"
GROUP="${2:-$USER}"

if [[ -z "${USER}" ]]; then
  echo "$ScriptFileName: error: USER argument is not set." >&2
  Exit -255
fi

if [[ -z "${GROUP}" ]]; then
  echo "$ScriptFileName: error: GROUP argument is not set." >&2
  Exit -254
fi

function Call()
{
  echo ">$@"
  "$@"
  LastError=$?
  return $LastError
}

CONFIGURE_ROOT="`/bin/readlink -f "$ScriptDirPath/../.."`"

echo "Updating permissions for user=\"$USER\" and group=\"$GROUP\"..."

Call sudo chown -R ${USER}:${GROUP} "${CONFIGURE_ROOT}"
Call sudo chmod -R ug+rw "${CONFIGURE_ROOT}"

IFS=$' \t\r\n'; for file in `find "${CONFIGURE_ROOT}" -type f -name "*.sh"`; do
  Call sudo chmod ug+x "$file"
done

echo "Done."

exit 0

fi
