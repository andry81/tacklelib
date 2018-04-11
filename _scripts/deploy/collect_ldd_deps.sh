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

function Call()
{
  echo ">$@"
  eval "$@"
  LastError=$?
  return $LastError
}

function Pushd()
{
  pushd "$@" > /dev/null
}

function Popd()
{
  popd "$@" > /dev/null
}

function FindFiles()
{
  RETURN_VALUE=()

  local file_list_to_find=()

  local IFS
  local file
  local i

  IFS=":"

  i=0

  Pushd "$SEARCH_ROOT" && {
    for file in $FILE_LIST_TO_FIND; do
      if [[ -f "$file" ]]; then
        file_list_to_find[i++]="$file"
        echo "  $file"
        (( i++ ))
      fi
    done
    Popd
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

function RemoveEmptyArgs()
{
  RETURN_VALUE=()

  local args
  args=("$@")

  local arg
  local i
  local j

  local IFS=$' \t\r\n'

  i=0
  j=0
  for arg in "${args[@]}"; do
    if [[ -n "$arg" ]]; then
      RETURN_VALUE[j++]="$arg"
    fi
    (( i++ ))
  done
}

function GetCanonicalPath()
{
  local file_in="$1"
  local file_in_abs

  if [[ -n "$file_in" ]]; then
    # Use `readlink` to convert a path from any not globbed path into canonical path, but
    # use not existed path prefix to avoid convertion from a symlink.
    if [[ "${file_in:0:1}" == "." || "${file_in:0:1}" != "/" ]]; then
      file_in_abs=$(readlink -m "/::$(pwd)/$file_in")
    else
      file_in_abs=$(readlink -m "/::$file_in")
    fi

    RETURN_VALUE="${file_in_abs#/::}"
  else
    RETURN_VALUE="."
  fi
}

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

function MakeSymlink()
{
  local flag_args=()
  local IFS

  ReadCommandLineFlags flag_args "$@"
  (( ${#flag_args[@]} )) && shift ${#flag_args[@]}

  local ignore_if_same_link_exist=0
  local flag
  local i

  IFS=$' \t\r\n'

  i=0
  for flag in "${flag_args[@]}"; do
    if [[ "${flag//I/}" != "$flag" ]]; then
      ignore_if_same_link_exist=1
      flag_args[i]="${flag//I/}" # remove external flag
      if [[ -z "${flag_args[i]//-/}" ]]; then
        flag_args[i]=""
      fi
      break
    fi
    (( i++ ))
  done

  RemoveEmptyArgs "${flag_args[@]}"
  flag_args=("${RETURN_VALUE[@]}")

  local Name="$1"
  local Path="$2"

  GetCanonicalPath "$Name"
  local LinkPath="$RETURN_VALUE"

  GetCanonicalPath "$Path"
  local RefPath="$RETURN_VALUE"

  if (( ignore_if_same_link_exist )); then
    # check if symlink with the same path already exist
    if [[ -f "$Name" && -L "$Name" ]]; then
      local PrevRefPath=$(readlink -e "$Name")
      [[ "$RefPath" == "$PrevRefPath" ]] && return 0
    fi
  fi

  echo ">ln: ${flag_args[@]} \"$LinkPath\" -> \"$RefPath\""
  ln -s "${flag_args[@]}" "$Path" "$Name"

  return $?
}

function CopyFile()
{
  local flag_args=()
  local IFS

  ReadCommandLineFlags flag_args "$@"
  (( ${#flag_args[@]} )) && shift ${#flag_args[@]}

  local create_symlinks=0
  local flag
  local i

  IFS=$' \t\r\n'

  i=0
  for flag in "${flag_args[@]}"; do
    if [[ "${flag//L/}" != "$flag" ]]; then
      create_symlinks=1
      flag_args[i]="${flag//L/}" # remove external flag
      if [[ -z "${flag_args[i]//-/}" ]]; then
        flag_args[i]=""
      fi
      break
    fi
    (( i++ ))
  done

  RemoveEmptyArgs "${flag_args[@]}"
  flag_args=("${RETURN_VALUE[@]}")

  local FILE_IN="$1"
  shift

  if [[ -z "$FILE_IN" ]]; then
    echo "CopyFile: error: input file is not set."
    return 255
  fi 1>&2

  # convert to canonical path
  GetCanonicalPath "$FILE_IN"
  local file_in="$RETURN_VALUE"

  # split canonical path into components
  GetFileDir "$file_in"
  local file_in_dir="$RETURN_VALUE"

  GetFileName "$file_in"
  local file_in_name="$RETURN_VALUE"

  local file
  local file_dir
  local file_name
  local link_file
  local link_file_dir
  local copy_to_file
  local copy_to_file_abs
  local copy_to_file_dir
  local copy_to_file_name
  local copy_to_list
  local i

  IFS=$' \t\r\n'

  for file in `find "$file_in_dir" -maxdepth 1 -type f -name "$file_in_name" -o -type l -name "$file_in_name"`; do
    if [[ -f "$file" && ! -L "$file" ]]; then
      GetFileDir "$file"
      file_dir="$RETURN_VALUE"

      copy_to_list=()
      i=0
      for copy_to_file in "$@"; do
        GetCanonicalPath "$copy_to_file"
        copy_to_file_abs="$RETURN_VALUE"

        if [[ -d "$copy_to_file_abs" ]]; then
          GetFileDir "$copy_to_file_abs/"
        else
          GetFileDir "$copy_to_file_abs"
        fi
        copy_to_file_dir="$RETURN_VALUE"

        if [[ "$file_dir" != "$copy_to_file_dir" ]]; then
          copy_to_list[i++]="$copy_to_file_abs"
        fi
      done

      if (( ${#copy_to_list[@]} )); then
        Call cp "${flag_args[@]}" "$file" "${copy_to_list[@]}" || return $?
      fi
    elif [[ -L "$file" ]]; then
      if (( create_symlinks )); then
        link_file="$(readlink -f "$file")"

        # symlink to a regular file or another symlink
        if [[ -f "$link_file" ]]; then
          GetFileName "$link_file"
          link_file_name="$RETURN_VALUE"

          CopyFile "${flag_args[@]}" "$link_file" "$@" || return $?

          GetFileName "$file"
          file_name="$RETURN_VALUE"

          if [[ "$link_file_name" != "$file_name" ]]; then
            for copy_to_file in "$@"; do
              GetCanonicalPath "$copy_to_file"
              copy_to_file_abs="$RETURN_VALUE"

              if [[ -d "$copy_to_file_abs" ]]; then
                GetFileDir "$copy_to_file_abs/"
              else
                GetFileDir "$copy_to_file_abs"
              fi
              copy_to_file_dir="$RETURN_VALUE"

              Pushd "$copy_to_file_dir" && {
                MakeSymlink -I "$file_name" "$link_file_name"
                Popd
              }
            done
          fi
        fi
      fi
    fi
  done

  return 0
}

function CollectLddDeps()
{
  local LDD_TOOL=ldd #alternative: `lddtee`

  echo "Scanning for \"$FILE_LIST_TO_FIND\" files in \"$SEARCH_ROOT\"..."

  FindFiles || return 10

  (( ! ${#RETURN_VALUE[@]} )) && return 11

  echo
  echo "Reading and collecting dependencies..."

  local IFS=$' \t\r\n'

  local LinkName
  local Op
  local RefPath
  local Address

  [[ -n "$OUT_DEPS_FILE" ]] && echo -n "" > "$OUT_DEPS_FILE"

  (
    # external shell process to isolate the change of exported variables

    for scan_file in "${RETURN_VALUE[@]}"; do
      echo "  $scan_file"
      [[ -n "$OUT_DEPS_FILE" ]] && echo "#%% $scan_file" >> "$OUT_DEPS_FILE"

      # We must set `LD_LIBRARY_PATH=$SEARCH_ROOT` to resolve local dependencies and
      # enable to collect dependencies after the `ld-linux.so` module.
      export LD_LIBRARY_PATH="$SEARCH_ROOT"

      # first check the exit code because `ldd` prints an error to stdout instead of stderr
      $LDD_TOOL "$scan_file" > /dev/null || continue

      $LDD_TOOL "$scan_file" | while read -r LinkName Op RefPath Address; do
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
          CopyFile -L "$RefPath" "$OUT_DEPS_DIR/"
        elif [[ -n "$LinkName" && -f "$LinkName" ]]; then
          echo "    V $LinkName -> ${RefPath:-X} $Address"
          CopyFile -L "$LinkName" "$OUT_DEPS_DIR/"
        else
          echo "    X $LinkName -> ${RefPath:-X} $Address"
        fi
      done
    done
  )

  return 0
}

CollectLddDeps

exit $?

fi
