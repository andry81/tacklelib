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

ScriptFileNamePrefix="${ScriptFileName%[.]*}"

function CallLr()
{
  local IFS=$' \t\r\n'
  echo ">$@"
  "$@"
  LastError=$?
  echo
  return $LastError
} 

function Call()
{
  local IFS=$' \t\r\n'
  echo ">$@"
  "$@"
  LastError=$?
  return $LastError
} 

function GetTime()
{
  local separator=${1:-_}

  date_prefix=$(date +%Y${separator}%m${separator}%H${separator}%M${separator}%S)
  date_nanosec=$(date +%N)

  date_formatted_msec=${date_nanosec}
  while [[ "${date_formatted_msec:0:1}" == "0" ]]; do date_formatted_msec=${date_formatted_msec:1}; done
  date_formatted_msec=$(( ${date_formatted_msec:-0} / 1000000 ))
  printf -v date_formatted_msec "%03d" "$date_formatted_msec"
}

# WORKAROUND for `file is not found` when run from GUI shell
cd "$ScriptDirPath"

# with logs rotation
LogFilesDir="$ScriptDirPath/logs"
LogFileNamePrefix="$ScriptFileNamePrefix"
LogFileName="$LogFileNamePrefix.log"
LogFilePath="$LogFilesDir/$LogFileName"
MaxFileSize=$(( 1024 * 1024 ))

[[ ! -d "$LogFilesDir" ]] && mkdir "$LogFilesDir"

# print data and time of execution both to the log and into stdout
(
(
(
  GetTime

  if [[ -f "$LogFilePath" ]]; then
    file_size=$(du -b "$LogFilePath" | { read -r size suffix; echo $size; })
    if (( file_size > MaxFileSize )); then
      timestamp="${date_prefix}_${date_formatted_msec}"

      mv "$LogFilePath" "$LogFilesDir/$LogFileNamePrefix.$timestamp.log"
      touch "$LogFilePath"
    fi
  fi

  echo
  echo "----"
  echo "---- Start time: $date_prefix.$date_formatted_msec"
  echo "---- cwd=\"$(pwd)\""
  echo "----"

  # export variables
  Call export LD_LIBRARY_PATH=".:./lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
  #export QT_QPA_FONTDIR=./lib/fonts

  IFS=$' \t\r\n'
  CallLr "$ScriptDirPath/$ScriptFileNamePrefix" "$@"

  GetTime

  echo "----"
  echo "---- End time: $date_prefix.$date_formatted_msec"
  echo "----"
  echo

) 2>&1 1>&5 | tee -a "$LogFilePath" >&9 2>&9 # temporary redirect stderr to the stream descriptor 9
) 5>&1 | tee -a "$LogFilePath" >&8 2>&9 # temporary redirect stdout to the stream descriptor 8
) 8>&1 9>&2 # redirect the stream descriptors 8 and 9 back to stdout and stderr

fi
