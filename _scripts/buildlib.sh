#!/bin/bash

# Script can be ONLY included by "source" command.
if [[ -n "$BASH" && (-z "$BASH_LINENO" || ${BASH_LINENO[0]} -gt 0) ]] && (( ! ${#SOURCE_BUILDLIB_SH} )); then 

SOURCE_BUILDLIB_SH=1 # including guard

source "/bin/bash_entry" || exit $?
source "${ScriptDirPath:-.}/traplib.sh" || exit $?

# Special exit code value variable has used by the specific set of functions
# like `Call` and `Exit` to hold the exit code over the builtin functions like
# `pushd` and `popd` which are changes the real exit code.
LastError=0

[[ -z "$NEST_LVL" ]] && export NEST_LVL=0

function Pause()
{
  local key
  read -n1 -r -p "Press any key to continue..." key
  echo
}

function Exit()
{
  (( NEST_LVL-- ))

  #[[ $NEST_LVL -eq 0 ]] && Pause

  if [[ $# -eq 0 ]]; then
    exit $LastError
  else
    exit $@
  fi
}

function Call()
{
  local IFS=$' \t\r\n'
  MakeCommandLine '' 1 "$@"
  echo ">$RETURN_VALUE"
  "$@"
  LastError=$?
  return $LastError
}

function CallAndPrintIf()
{
  local IFS=$' \t\r\n'
  MakeCommandLine '' 1 "${@:2}"
  eval "$1" && echo ">$RETURN_VALUE"
  "${@:2}"
  LastError=$?
  return $LastError
}

function SetError()
{
  return $LastError
}

function Pushd()
{
  local IFS=$' \t\r\n'
  if [[ -z "$@" ]]; then
    echo "Pushd: error: directory is not set." >&2
    return 254
  fi
  pushd "$@" > /dev/null
}

function Popd()
{
  local IFS=$' \t\r\n'
  popd "$@" > /dev/null
}

function ReadCommandLineFlags()
{
  local out_args_list_name_var="$1"
  shift

  local IFS=$' \t\r\n'
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

  local IFS=$' \t\r\n'
  local args
  args=("$@")

  local arg
  local i
  local j

  i=0
  j=0
  IFS=$' \t\r\n'; for arg in "${args[@]}"; do
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
    # use not existed path prefix to avoid conversion from a symlink.
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

function MakeDir()
{
  local flag_args=()
  local IFS=$' \t\r\n'

  ReadCommandLineFlags flag_args "$@"
  (( ${#flag_args[@]} )) && shift ${#flag_args[@]}

  local arg
  IFS=$' \t\r\n'; for arg in "$@"; do
    [[ ! -d "$arg" ]] && {
      MakeCommandLine '' 1 "$arg"
      IFS=$' \t\r\n'
      echo ">mkdir ${flag_args[@]} $RETURN_VALUE"
      mkdir "${flag_args[@]}" "$arg" || return $?
    }
  done

  return 0
}

function MoveFile()
{
  local flag_args=()
  local IFS=$' \t\r\n'

  ReadCommandLineFlags flag_args "$@"
  (( ${#flag_args[@]} )) && shift ${#flag_args[@]}

  local move_symlinks=0
  local flag
  local i

  i=0
  IFS=$' \t\r\n'; for flag in "${flag_args[@]}"; do
    if [[ "${flag//L/}" != "$flag" ]]; then
      move_symlinks=1
      flag_args[i]="${flag//L/}" # remove external flag
      if [[ -z "${flag_args[i]//-/}" ]]; then
        flag_args[i]=""
      fi
      break
    fi
    (( i++ ))
  done

  IFS=$' \t\r\n'
  RemoveEmptyArgs "${flag_args[@]}"
  flag_args=("${RETURN_VALUE[@]}")

  local FILE_IN="$1"
  shift

  if [[ -z "$FILE_IN" ]]; then
    echo "MoveFile: error: input file is not set." >&2
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

  local find_cmd
  if (( move_symlinks )); then
    find_cmd="find \"\$file_in_dir\" -maxdepth 1 -type f -name \"\$file_in_name\" -o -type l -name \"\$file_in_name\""
  else
    find_cmd="find \"\$file_in_dir\" -maxdepth 1 -type f -name \"\$file_in_name\""
  fi

  IFS=$' \t\r\n'; for file in `eval $find_cmd`; do
    MakeCommandLine '' 1 "$file" "$@"
    IFS=$' \t\r\n'
    echo ">mv ${flag_args[@]} $RETURN_VALUE"
    mv "${flag_args[@]}" "$file" "$@" || return $?
  done

  return 0
}

function JoinArgs()
{
  local IFS="$1"
  shift
  RETURN_VALUE="$*"
}

# Portable implementation between wide set of targets:
#   * cygwin 1.5.x
#   * cygwin 1.7.x
#   * msys 1.0.11.x
#   * mingw
#   * linux mint 18.3 x64

function FindChar()
{
  # drop return value
  RETURN_VALUE=""

  # (Required) String which would be searched.
  local String="$1"
  # (Required) Chars for search.
  local Chars="$2"

  if [[ -z "$String" ]]; then
    RETURN_VALUE="-1"
    return 1
  fi
  if [[ -z "$Chars" ]]; then
    RETURN_VALUE="-1"
    return 2
  fi

  local StringLen="${#String}"
  local CharsLen="${#Chars}"
  local i
  local j
  for (( i=0; i < StringLen; i++ )); do
    for (( j=0; j < CharsLen; j++ )); do
      if [[ "${String:$i:1}" == "${Chars:$j:1}" ]]; then
        RETURN_VALUE="$i"
        return 0
        break
      fi
    done
  done

  RETURN_VALUE="-1"

  return 3
}

# to load command line from a file into an array
function MakeCommandArgumentsFromFile()
{
  # drop return value
  RETURN_VALUE=""

  local Flags="$1"
  local FilePath="$2"
  
  local DoEval=0
  local AlwaysQuoting=0

  if [[ "${Flags//-/}" != "" && "${Flags#-}" != "$Flags" ]]; then
    [[ "${Flags//e/}" != "$Flags" ]] && DoEval=1
    [[ "${Flags//q/}" != "$Flags" ]] && AlwaysQuoting=1
  fi

  if [[ "$FilePath" != '-' ]]; then
    ConvertBackendPathToNative "$FilePath" s || return 1
    FilePath="$RETURN_VALUE"
    [[ -f "$FilePath" ]] || return 2
  fi

  local ConfigString=""

  function InternalRead()
  {
    local i
    local ConfigLine=""
    local IgnoreLine=0
    local IsEscapedSequence=0
    local ConfigLineLen

    local IFS='' # enables read whole string line into a single variable

    while read -r ConfigLine; do
      IsEscapedSequence=0
      IgnoreLine=0
      ConfigLineLen="${#ConfigLine}"
      for (( i=0; i<ConfigLineLen; i++ )); do
        case "${ConfigLine:i:1}" in
          $'\n') ;;
          $'\r') ;;

          \\)
            if (( ! IsEscapedSequence )); then
              IsEscapedSequence=1
            else
              IsEscapedSequence=0
            fi
            ;;

          \#)
            if (( ! IsEscapedSequence )); then
              IgnoreLine=1
              ConfigLine="${ConfigLine:0:i}"
              break
            else
              IsEscapedSequence=0
            fi
            ;;

          *)
            (( ! IsEscapedSequence )) || IsEscapedSequence=0
            ;;
        esac
        (( ! IgnoreLine )) || break
      done

      ConfigLine="${ConfigLine#"${ConfigLine%%[^[:space:]]*}"}" # remove beginning whitespaces
      ConfigLine="${ConfigLine%"${ConfigLine##*[^[:space:]]}"}" # remove ending whitespaces
      # remove last backslash
      if (( ${#ConfigLine} )) && [[ "${ConfigLine:${#ConfigLine}-1:1}" == '\' ]]; then #'
        ConfigLine="${ConfigLine:0:${#ConfigLine}-1}"
      fi
      if [[ -n "$ConfigLine" ]]; then
        if (( DoEval )); then
          EscapeString "$ConfigLine" '"' 0
          eval ConfigLine=\"$RETURN_VALUE\"
        fi
        EscapeString "$ConfigLine" '' 1
        ConfigLine="$RETURN_VALUE"
        if (( AlwaysQuoting )) || [[ "${ConfigLine//[$' \t\r\n'=]/}" != "$ConfigLine" ]]; then
          ConfigString="$ConfigString${ConfigString:+" "}'${ConfigLine}'"
        else
          ConfigString="$ConfigString${ConfigString:+" "}${ConfigLine}"
        fi
      fi
    done
  }

  if [[ "$FilePath" != '-' ]]; then
    InternalRead < "$FilePath"
  else
    InternalRead
  fi

  RETURN_VALUE="$ConfigString"

  return 0
}

# to convert command line from an array to a string
function MakeCommandLine()
{
  local IFS=$' \t\r\n' # workaround for the bug in the "[@]:i" expression under the bash version lower than 4.1
  MakeCommandLineEx "$1" "$2" '' '' "${@:3}"
}

function MakeCommandLineEx()
{
  # drop return value
  RETURN_VALUE=""

  # (Required) Set of characters in string which are gonna be escaped.
  local EscapeChars="$1"
  # (Required) Type of escaping:
  #   0 - Argument will be quoted by " character, so escape any character from
  #       "EscapeChars" by the \ character.
  #   1 - Arguments will be quoted by the ' character, so the ' character shall
  #       be escaped by \' sequance. The "EscapeChars" variable doesn't used in this case.
  #   2 - Argument will be quoted by the " character and used in the cmd.exe shell,
  #       so escape any character from the "EscapeChars" variable by the ^ character and escape
  #       result by the \ character to put it in a ""-quoted string.
  local EscapeType="$2"
  # (Optional) Predicate functions:
  #   Calls before/after each argument being processed.
  local PredicatePrefixFunc="$3"
  local PredicateSuffixFunc="$4"
  local EscapeFlags="${EscapeType#*:}"

  if (( ${#EscapeType} == ${#EscapeFlags} )); then
    EscapeFlags=""
  else
    EscapeType="${EscapeType%%:*}"
  fi

  [[ -z "$EscapeType" ]] && EscapeType=0

  shift 4

  local IFS=$' \t\r\n'
  local Args
  Args=("$@")

  local CommandLine=""
  local AlwaysQuoting=0

  [[ "${EscapeFlags//a/}" != "$EscapeFlags" ]] && AlwaysQuoting=1

  local arg
  local i=0

  case "$EscapeType" in
    0)
      IFS=$' \t\r\n'; for arg in "${Args[@]}"; do
        [[ -n "$PredicatePrefixFunc" ]] && "$PredicatePrefixFunc" CommandLine $i "$arg"
        EscapeString "$arg" "$EscapeChars" 0
        if (( AlwaysQuoting )) || [[ "${RETURN_VALUE//[ $'\t\r\n']/}" != "$RETURN_VALUE" ]]; then
          # we must quote white space characters in an argument to avoid argument splitting
          CommandLine="$CommandLine${CommandLine:+" "}\"$RETURN_VALUE\""
        else
          CommandLine="$CommandLine${CommandLine:+" "}$RETURN_VALUE"
        fi
        [[ -n "$PredicateSuffixFunc" ]] && "$PredicateSuffixFunc" CommandLine $i "$arg"
        (( i++ ))
      done
      ;;

    1)
      IFS=$' \t\r\n'; for arg in "${Args[@]}"; do
        [[ -n "$PredicatePrefixFunc" ]] && "$PredicatePrefixFunc" CommandLine $i "$arg"
        EscapeString "$arg" "$EscapeChars" 1
        if (( AlwaysQuoting )) || [[ "${RETURN_VALUE//[ $'\t\r\n']/}" != "$RETURN_VALUE" ]]; then
          # we must quote white space characters in an argument to avoid argument splitting
          CommandLine="$CommandLine${CommandLine:+" "}'$RETURN_VALUE'"
        else
          CommandLine="$CommandLine${CommandLine:+" "}$RETURN_VALUE"
        fi
        [[ -n "$PredicateSuffixFunc" ]] && "$PredicateSuffixFunc" CommandLine $i "$arg"
        (( i++ ))
      done
      ;;

    2)
      IFS=$' \t\r\n'; for arg in "${Args[@]}"; do
        [[ -n "$PredicatePrefixFunc" ]] && "$PredicatePrefixFunc" CommandLine $i "$arg"
        EscapeString "$arg" "$EscapeChars" 2
        EscapeString "$RETURN_VALUE" '' 0
        if (( AlwaysQuoting )) || [[ "${RETURN_VALUE//[ $'\t\r\n']/}" != "$RETURN_VALUE" ]]; then
          CommandLine="$CommandLine${CommandLine:+" "}\"$RETURN_VALUE\""
        else
          CommandLine="$CommandLine${CommandLine:+" "}$RETURN_VALUE"
        fi
        [[ -n "$PredicateSuffixFunc" ]] && "$PredicateSuffixFunc" CommandLine $i "$arg"
        (( i++ ))
      done
      ;;
  esac

  RETURN_VALUE="$CommandLine"

  return 0
}

fi
