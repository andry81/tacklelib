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

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
  echo "Usage: <SearchRoot> <File1>[:<File2>[:...[:<FileN>]]] <OutDepsFile> <OutDepsDir>"
  echo "Example: $ScriptFileName .. \"*.so:*.so.*\" deps.lst ."
  exit 1
fi

APP_ROOT="`readlink -f "$ScriptDirPath/.."`"

SEARCH_ROOT="$1"        # directory path where to search executable files not recursively
FILE_LIST_TO_FIND="$2"  # `:`-separated list of wildcard case insensitive file names or file paths
OUT_DEPS_FILE="$3"      # output dependencies text file
OUT_DEPS_DIR="$4"       # directory there to copy found dependencies


if [[ -n "$OUT_DEPS_FILE" ]]; then
  touch "$OUT_DEPS_FILE" 2> /dev/null || {
    echo "$ScriptFileName: error: cannot create OUT_DEPS_FILE file: \"$OUT_DEPS_FILE\"".
    exit 2
  } 1>&2
fi

if [[ -z "$OUT_DEPS_DIR" || ! -d "$OUT_DEPS_DIR" ]]; then
  echo "$ScriptFileName: error: directory OUT_DEPS_DIR does not exist: \"$OUT_DEPS_DIR\"".
  exit 3
fi 1>&2

if [[ -z "$SEARCH_ROOT" || ! -d "$SEARCH_ROOT/" ]]; then
  SEARCH_ROOT="$APP_ROOT"
else
  SEARCH_ROOT="`readlink -f "$SEARCH_ROOT"`"
fi

function FindFiles()
{
  RETURN_VALUE=()

  local file_list_to_find=()

  local IFS
  local file
  local i

  IFS=":"

  i=0

  pushd "$SEARCH_ROOT" > /dev/null && {
    for file in $FILE_LIST_TO_FIND; do
      if [[ -f "$file" ]]; then
        file_list_to_find[i++]="$file"
        echo "  $file"
        (( i++ ))
      fi
    done
    popd > /dev/null
  }

  (( ! ${#file_list_to_find[@]} )) && return 1

  IFS=$' \t\r\n'

  local iname_cmd_line=""
  for arg in "${file_list_to_find[@]}"; do
    if [[ -n "$iname_cmd_line" ]]; then
      iname_cmd_line="$iname_cmd_line -o -iname \"$arg\""
    else
      iname_cmd_line="-type f -iname \"$arg\""
    fi
  done

  i=0
  for file in `eval find "\$SEARCH_ROOT/" $iname_cmd_line`; do
    RETURN_VALUE[i++]="$file"
    echo "  -> $file"
    (( i++ ))
  done

  return 0
}

function CollectLddDeps()
{
  echo "Scanning for \"$FILE_LIST_TO_FIND\" files in \"$SEARCH_ROOT\"..."

  FindFiles || return 10

  (( ! ${#RETURN_VALUE[@]} )) && return 11

  echo
  echo "Reading dependencies..."

  local IFS=$' \t\r\n'

  local LinkName
  local Op
  local RefPath
  local Address

  [[ -n "$OUT_DEPS_FILE" ]] && echo -n "" > "$OUT_DEPS_FILE"

  for scan_file in "${RETURN_VALUE[@]}"; do
    echo "  $scan_file"
    [[ -n "$OUT_DEPS_FILE" ]] && echo "#%% $scan_file" >> "$OUT_DEPS_FILE"

    ldd "$scan_file" | while read -r LinkName Op RefPath Address; do
      if [[ "$Op" != "=>" ]]; then
        Address="$RefPath"
        RefPath="$Op"
      fi

      if [[ -n "$RefPath" && "${RefPath:0:1}" != "/" ]]; then
        if [[ "${RefPath:0:1}" == "(" ]]; then
          Address="${RefPath:1:-1}"
          RefPath="."
        else
          Address=""
          RefPath=""
        fi
      else
        if [[ "${Address:0:1}" == "(" ]]; then
          Address="${Address:1:-1}"
        fi
      fi

      [[ -n "$OUT_DEPS_FILE" ]] && echo "$LinkName:$RefPath:$Address" >> "$OUT_DEPS_FILE"

      if [[ -n "$RefPath" && -f "$RefPath" ]]; then
        echo "    V $LinkName -> ${RefPath:-X} $Address"
        cp "$RefPath" "$OUT_DEPS_DIR/"
      elif [[ -n "$LinkName" && -f "$LinkName" ]]; then
        echo "    V $LinkName -> ${RefPath:-X} $Address"
        cp "$LinkName" "$OUT_DEPS_DIR/"
      else
        echo "    X $LinkName -> ${RefPath:-X} $Address"
      fi
    done
  done

  return 0
}

CollectLddDeps

exit $?

fi
