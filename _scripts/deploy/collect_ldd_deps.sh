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

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
  echo "Usage: <SearchRoot> <File1>[:<File2>[:...[:<FileN>]]] <OutDepsFile> <OutDepsDir>"
  echo "Example: $ScriptFileName .. \"*.so:*.so.*\" deps.lst ."
  exit 1
fi

APP_ROOT="`readlink -f "$ScriptDirPath/.."`"

SEARCH_ROOT_LIST="$1"     # directory path list where to start search files dependencies not recursively
FILE_LIST_TO_FIND="$2"    # `:`-separated list of wildcard case insensitive file names or file paths to find
FILE_LIST_TO_EXCLUDE="$3" # `:`-separated list of wildcard case insensitive file names or file paths to exclude
LD_LIBRARY_PATH_LIST="$4" # directory path list for the LD_LIBRARY_PATH
OUT_DEPS_FILE="$5"        # output dependencies text file
OUT_DEPS_DIR="$6"         # directory there to copy found dependencies


if [[ -n "$OUT_DEPS_FILE" ]]; then
  touch "$OUT_DEPS_FILE" 2> /dev/null || {
    echo "$ScriptFileName: error: cannot create OUT_DEPS_FILE file: \"$OUT_DEPS_FILE\"."
    exit 2
  } 1>&2
fi

if [[ ! -d "$OUT_DEPS_DIR" ]]; then
  echo "$ScriptFileName: error: directory OUT_DEPS_DIR is not found: \"$OUT_DEPS_DIR\"." >&2
  exit 3
fi

if [[ ! -d "$CWD" ]]; then
  CWD="$APP_ROOT"
else
  CWD="`readlink -f "$CWD"`"
fi

function Call()
{
  echo ">$@"
  "$@"
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
  file_list_to_find=()
  file_list_to_exclude=()
  file_list_found=()

  local IFS
  local search_root
  local file
  local file2
  local i

  i=0
  local IFS=$':\t\r\n'; for search_root in $SEARCH_ROOT_LIST; do
    if Pushd "$search_root"; then
      local IFS=$':\t\r\n'; for file in $FILE_LIST_TO_FIND; do
        if [[ -f "$file" ]]; then
          file_list_to_find[i++]="$file"
          echo "  +$file"
          (( i++ ))
        fi
      done
      Popd
    else
      echo "$ScriptFileName: error: search root is not found: \"$search_root\"." >&2
      return 1
    fi
  done

  (( ! ${#file_list_to_find[@]} )) && {
    echo "$ScriptFileName: warning: file search list is empty." >&2
    return 2
  }

  i=0

  local IFS=$':\t\r\n'; for file in $FILE_LIST_TO_EXCLUDE; do
    file_list_to_exclude[i++]="$file"
    echo "  -$file"
    (( i++ ))
  done

  # for lowercase comparison globbing
  local SHELLNOCASEMATCH=`shopt -p nocasematch`
  shopt -s nocasematch

  local file_name
  local file_name2
  local is_file_excluded
  local iname_cmd_line=""
  for file in "${file_list_to_find[@]}"; do
    GetFileName "$file"
    file_name="$RETURN_VALUE"
    is_file_excluded=0
    for file2 in "${file_list_to_exclude[@]}"; do
      GetFileName "$file2"
      file_name2="$RETURN_VALUE"
      if [[ "$file_name" == "$file_name2" ]]; then
        is_file_excluded=1
        break # excluded
      fi
    done
    if (( !is_file_excluded )); then
      if [[ -n "$iname_cmd_line" ]]; then
        iname_cmd_line="$iname_cmd_line -o -iname \"$file\""
      else
        iname_cmd_line="-type f -iname \"$file\""
      fi
    fi
  done

  # restore previous case comparison globbing
  eval $SHELLNOCASEMATCH

  i=0

  local IFS=$':\t\r\n'; for search_root in $SEARCH_ROOT_LIST; do
    local IFS=$' \t\r\n'; for file in `eval find "\$search_root/" $iname_cmd_line`; do
      file_list_found[i++]="$file"
      echo "  -> $file"
      (( i++ ))
    done
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
    if [[ "${args[i]//-/}" != "" && "${args[i]#-}" != "${args[i]}" ]]; then
      eval "$out_args_list_name_var[j++]=\"\${args[i]}\""
      shift
    else
      break # stop on empty string too
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

  ReadCommandLineFlags flag_args "$@"
  (( ${#flag_args[@]} )) && shift ${#flag_args[@]}

  local ignore_if_same_link_exist=0
  local flag
  local i

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

  ReadCommandLineFlags flag_args "$@"
  (( ${#flag_args[@]} )) && shift ${#flag_args[@]}

  local create_symlinks=0
  local flag
  local i

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
    echo "CopyFile: error: input file is not set." >&2
    return 255
  fi

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

  local IFS=$' \t\r\n'; for file in `find "$file_in_dir" -maxdepth 1 -type f -name "$file_in_name" -o -type l -name "$file_in_name"`; do
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

function AppendItemToUArray()
{
  # drop return value
  RETURN_VALUE=-1

  local i
  local item
  declare -a "UArraySize=(\${#$1[@]})"

  for (( i=0; i<UArraySize; i++ )); do
    eval "item=\"\${$1[i]}\""
    if [[ "$item" == "$2" ]]; then
      RETURN_VALUE=$i
      return 1
    fi
  done

  eval "$1[UArraySize]=\"\$2\""

  RETURN_VALUE=$UArraySize

  return 0
}

function RemoveItemFromUArray()
{
  local IFS=$' \t\r\n' # workaround for the bug in the "[@]:i" expression under the bash version lower than 4.1

  local i
  local item
  declare -a "UArraySize=(\${#$1[@]})"
  for (( i=0; i<UArraySize; i++ )); do
    eval "item=\"\${$1[i]}\""
    if [[ "$item" == "$2" ]]; then
      # remove it from the array
      eval "$1=(\"\${$1[@]:0:\$i}\" \"\${$1[@]:\$i+1}\")"
      return 0
    fi
  done

  return 1
} 
function CollectLddDeps()
{
  local LDD_TOOL=ldd #alternative: `lddtee`

  echo "Scanning for \"$FILE_LIST_TO_FIND\" with current working directory in \"$CWD\"..."

  local file_list_to_find
  local file_list_to_exclude
  local file_list_found

  FindFiles
  local LastError=$?

  (( LastError != 0 && LastError != 2 )) && return $LastError
  (( LastError == 2 )) && return 0

  if (( ! ${#file_list_found[@]} )); then
    echo "$ScriptFileName: info: nothing to search." >&2
    return 10
  fi

  echo
  echo "Reading and collecting dependencies..."

  local IFS

  local LinkName
  local Op
  local RefPath
  local Address

  [[ -n "$OUT_DEPS_FILE" ]] && echo -n "" > "$OUT_DEPS_FILE"

  (
    # external shell process to isolate the change of exported variables

    function ctrl_c()
    {
        echo
        echo "** search interrupted **"

        return 255
    }

    trap ctrl_c INT

    # We use `LD_LIBRARY_PATH` to resolve all dependencies.
    export LD_LIBRARY_PATH="$LD_LIBRARY_PATH_LIST${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    echo
    echo "  LD_LIBRARY_PATH=$LD_LIBRARY_PATH"
    echo

    ldd_output_file=$(mktemp /tmp/ldd_output.XXXXXX)

    function on_exit()
    {
      rm "$ldd_output_file"
    }

    trap on_exit EXIT

    function CheckCopyTo()
    {
      local FromFile="$1"
      local ToDir="$2"

      # read the link and if the end file has the same file in the destination but different content, then stop with error immediately
      link_file="`readlink -f "$FromFile"`"

      GetFileDir "$link_file"
      link_file_dir="$RETURN_VALUE"

      GetFileName "$link_file"
      link_file_name="$RETURN_VALUE"

      if [[ "$link_file_dir" != "$ToDir" ]]; then
        if [[ -f "$ToDir/$link_file_name" ]]; then
          if ! cmp "$link_file" "$ToDir/$link_file_name" > /dev/null; then
            echo "$ScriptFileName: error: being copied dependency file is already exist with different content: \"$LinkName\" -> \"$link_file\" copy to \"$ToDir/\"" >&2
            return 1
          fi
          return 255
        fi
      fi

      return 0
    }

    # collect all not found dependencies to throw the error at the end of the search
    not_found_lib_list=()

    for scan_file in "${file_list_found[@]}"; do
      echo "  $scan_file"
      [[ -n "$OUT_DEPS_FILE" ]] && echo "#%% $scan_file" >> "$OUT_DEPS_FILE"

      # first check the exit code because `ldd` prints an error to stdout instead of stderr
      $LDD_TOOL "$scan_file" > "$ldd_output_file" || continue

      local IFS
      while IFS=$' \t\r\n' read -r LinkName Op RefPath Address; do
        if [[ "$Op" != "=>" ]]; then
          Address="$RefPath"
          RefPath="$Op"
        fi

        # ignore statical linkage message
        if [[ "$LinkName" == "statically" && "$RefPath" == "linked" ]]; then
          GetFileName "$scan_file"
          # remove from not found
          RemoveItemFromUArray not_found_lib_list "$RETURN_VALUE"
          continue
        fi

        if [[ -n "$RefPath" && "${RefPath:0:1}" != "/" ]]; then
          if [[ "${RefPath:0:1}" == "(" ]]; then
            Address="$RefPath"
            RefPath=""
          fi
        fi

        if [[ "${Address:0:1}" == "(" ]]; then
          Address="${Address:1:-1}"
        fi

        [[ -n "$OUT_DEPS_FILE" ]] && echo "$LinkName:$RefPath:$Address" >> "$OUT_DEPS_FILE"

        if [[ -n "$RefPath" && -f "$RefPath" ]]; then
          echo "    V $LinkName -> $RefPath $Address"
          CheckCopyTo "$RefPath" "$OUT_DEPS_DIR"
          LastError=$?
          if (( LastError > 0 && LastError < 255 )); then
            return 20
          elif (( ! LastError )); then
            CopyFile -L "$RefPath" "$OUT_DEPS_DIR/" || return 11
          fi
          # remove from not found
          RemoveItemFromUArray not_found_lib_list "$LinkName"
        elif [[ -n "$LinkName" && -f "$LinkName" ]]; then
          echo "    L $LinkName -> $LinkName $Address"
          CheckCopyTo "$LinkName" "$OUT_DEPS_DIR"
          LastError=$?
          if (( LastError > 0 && LastError < 255 )); then
            return 21
          elif (( ! LastError )); then
            CopyFile -L "$LinkName" "$OUT_DEPS_DIR/" || return 12
          fi
          # remove from not found
          RemoveItemFromUArray not_found_lib_list "$LinkName"
        else
          echo "    X $LinkName -> ${RefPath:-X} $Address"
          # append unique to not found list
          AppendItemToUArray not_found_lib_list "$LinkName"
        fi
      done < "$ldd_output_file"

      echo

      if (( ${#not_found_lib_list[@]} )); then
        echo " * not found: ${not_found_lib_list[@]}"
        echo
      fi
    done

    # for lowercase comparison globbing
    local SHELLNOCASEMATCH=`shopt -p nocasematch`
    shopt -s nocasematch

    local file
    local file_name
    for file in "${file_list_to_exclude[@]}"; do
      GetFileName "$file"
      file_name="$RETURN_VALUE"

      # remove specific not existed objects
      RemoveItemFromUArray not_found_lib_list "$file_name"
    done

    # restore previous case comparison globbing
    eval $SHELLNOCASEMATCH

    if (( ${#not_found_lib_list[@]} )); then
      echo "$ScriptFileName: error: having not found dependencies." >&2
      echo "$ScriptFileName: info: not found dependencies list:"

      for link_name in "${not_found_lib_list[@]}"; do
        echo "  ${link_name}"
      done
      echo

      return 11
    fi
  )

  return $?
}

CollectLddDeps || exit $?

echo "Done."
echo

exit 0

fi
