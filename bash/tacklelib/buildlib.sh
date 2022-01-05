#!/bin/bash

# Script can be ONLY included by "source" command.
[[ -z "$BASH" || (-n "$BASH_LINENO" && BASH_LINENO[0] -le 0) || (-n "$SOURCE_TACKLELIB_BUILDLIB_SH" && SOURCE_TACKLELIB_BUILDLIB_SH -ne 0) ]] && return

SOURCE_TACKLELIB_BUILDLIB_SH=1 # including guard

if [[ -z "$SOURCE_TACKLELIB_BASH_TACKLELIB_SH" || SOURCE_TACKLELIB_BASH_TACKLELIB_SH -eq 0 ]]; then
  echo."$0: error: \`bash_tacklelib\` must be included explicitly."
  exit 255
fi >&2

tkl_include_or_abort 'traplib.sh'
tkl_include_or_abort 'stringlib.sh'

[[ -z "$NEST_LVL" ]] && export NEST_LVL=0

# CAUTION:
#   Executes an external shell process in case of a script.
#
function tkl_call()
{
  local IFS=$' \t\r\n' # workaround for the bug in the "[@]:i" expression under the bash version lower than 4.1
  tkl_make_command_line '' 1 "$@"
  echo ">$RETURN_VALUE"
  tkl_pushset_source_file_components "$1" "${@:2}"
  tkl_push_trap 'tkl_pop_source_file_components' RETURN
  "$@"
  tkl_declare_global tkl__last_error $?
  return $tkl__last_error
}

# CAUTION:
#   Executes an external shell process in case of a script.
#
function tkl_call_and_print_if()
{
  local IFS=$' \t\r\n' # workaround for the bug in the "[@]:i" expression under the bash version lower than 4.1
  tkl_make_command_line '' 1 "${@:2}"
  eval "$1" && {
    echo ">$RETURN_VALUE"
  }
  tkl_pushset_source_file_components "$2" "${@:3}"
  tkl_push_trap 'tkl_pop_source_file_components' RETURN
  "${@:2}"
  tkl_declare_global tkl__last_error $?
  return $tkl__last_error
}

# CAUTION:
#   Executes in the same shell process in case of a script.
#
function tkl_call_inproc()
{
  local IFS=$' \t\r\n' # workaround for the bug in the "[@]:i" expression under the bash version lower than 4.1
  tkl_make_command_line '' 1 "$@"
  echo ">$RETURN_VALUE"
  tkl_pushset_source_file_components "$1" "${@:2}"
  tkl_push_trap 'tkl_pop_source_file_components' RETURN
  tkl_exec_inproc "$@"
  tkl_declare_global tkl__last_error $?
  return $tkl__last_error
}

# CAUTION:
#   Executes in the same shell process in case of a script.
#
function tkl_call_inproc_and_print_if()
{
  local IFS=$' \t\r\n' # workaround for the bug in the "[@]:i" expression under the bash version lower than 4.1
  tkl_make_command_line '' 1 "${@:2}"
  eval "$1" && {
    echo ">$RETURN_VALUE"
  }
  tkl_pushset_source_file_components "$2" "${@:3}"
  tkl_push_trap 'tkl_pop_source_file_components' RETURN
  tkl_exec_inproc "${@:2}"
  tkl_declare_global tkl__last_error $?
  return $tkl__last_error
}

# CAUTION:
#   Executes in the same shell process in case of a script.
#
function tkl_call_inproc_entry()
{
  local IFS=$' \t\r\n' # workaround for the bug in the "[@]:i" expression under the bash version lower than 4.1
  tkl_make_command_line '' 1 "${@:3}"
  echo ">$2: $1 $RETURN_VALUE"
  tkl_pushset_source_file_components "$2" "${@:3}"
  tkl_push_trap 'tkl_pop_source_file_components' RETURN
  tkl_exec_inproc_entry "$@"
  tkl_declare_global tkl__last_error $?
  return $tkl__last_error
}

# CAUTION:
#   Executes in the same shell process in case of a script.
#
function tkl_call_inproc_entry_and_print_if()
{
  local IFS=$' \t\r\n' # workaround for the bug in the "[@]:i" expression under the bash version lower than 4.1
  tkl_make_command_line '' 1 "${@:4}"
  eval "$1" && {
    echo ">$3: $2 $RETURN_VALUE"
  }
  tkl_pushset_source_file_components "$3" "${@:4}"
  tkl_push_trap 'tkl_pop_source_file_components' RETURN
  tkl_exec_inproc "${@:2}"
  tkl_declare_global tkl__last_error $?
  return $tkl__last_error
}

function tkl_remove_empty_args()
{
  RETURN_VALUE=()

  local args
  args=("$@")

  local i=0
  local j=0
  for arg in "${args[@]}"; do
    if [[ -n "$arg" ]]; then
      RETURN_VALUE[j++]="$arg"
    fi
    (( i++ ))
  done
}

function tkl_get_file_dir()
{
  local file_in="$1"

  if [[ -n "$file_in" ]]; then
    RETURN_VALUE="${file_in%/*}"
    [[ -z "$RETURN_VALUE" ]] && RETURN_VALUE="/"
  else
    RETURN_VALUE="."
  fi
}

function tkl_get_file_name()
{
  local file_in="$1"

  RETURN_VALUE="${file_in##*/}"
}

function tkl_make_dir()
{
  local flag_args=()

  tkl_read_command_line_flags flag_args "$@"
  (( ${#flag_args[@]} )) && shift ${#flag_args[@]}

  local arg
  for arg in "$@"; do
    [[ ! -d "$arg" ]] && {
      tkl_make_command_line '' 1 "$arg"
      echo ">mkdir ${flag_args[@]} $RETURN_VALUE"
      mkdir "${flag_args[@]}" "$arg" || return $?
    }
  done

  return 0
}

function tkl_move_file()
{
  local flag_args=()

  tkl_read_command_line_flags flag_args "$@"
  (( ${#flag_args[@]} )) && shift ${#flag_args[@]}

  local move_symlinks=0
  local flag
  local i=0
  for flag in "${flag_args[@]}"; do
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

  tkl_remove_empty_args "${flag_args[@]}"
  flag_args=("${RETURN_VALUE[@]}")

  local FILE_IN="$1"
  shift

  if [[ -z "$FILE_IN" ]]; then
    echo "tkl_move_file: error: input file is not set." >&2
    return 255
  fi

  # normalize path
  tkl_normalize_path -a "$FILE_IN"
  local file_in="$RETURN_VALUE"

  # split canonical path into components
  tkl_get_file_dir "$file_in"
  local file_in_dir="$RETURN_VALUE"

  tkl_get_file_name "$file_in"
  local file_in_name="$RETURN_VALUE"

  local find_cmd
  if (( move_symlinks )); then
    find_cmd="find \"\$file_in_dir\" -maxdepth 1 -type f -name \"\$file_in_name\" -o -type l -name \"\$file_in_name\""
  else
    find_cmd="find \"\$file_in_dir\" -maxdepth 1 -type f -name \"\$file_in_name\""
  fi

  local IFS=$' \t\r\n'
  for file in `eval $find_cmd`; do
    tkl_make_command_line '' 1 "$file" "$@"
    echo ">mv ${flag_args[@]} $RETURN_VALUE"
    mv "${flag_args[@]}" "$file" "$@" || return $?
  done

  return 0
}

function tkl_join_args()
{
  local IFS="$1"
  shift
  RETURN_VALUE="$*"
}

# Portable implementation between wide set of targets:
#   * cygwin 1.5+ or 1.7+
#   * msys 1.0.11.x or msys2 20190524+
#   * mingw
#   * linux mint 18.3 x64

# to load command line from a file into a string
function tkl_load_command_line_from_file()
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
    tkl_convert_backend_path_to_native "$FilePath" s || return 1
    FilePath="$RETURN_VALUE"
    [[ -f "$FilePath" ]] || return 2
  fi

  local ConfigString=""

  function tkl_internal_read_impl()
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
      for (( i=0; i < ConfigLineLen; i++ )); do
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
          tkl_escape_string "$ConfigLine" '"' 0
          eval "ConfigLine=\"$RETURN_VALUE\""
        fi
        tkl_escape_string "$ConfigLine" '' 1
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
    tkl_internal_read_impl < "$FilePath"
  else
    tkl_internal_read_impl
  fi

  unset tkl_internal_read_impl

  RETURN_VALUE="$ConfigString"

  return 0
}

# to convert command line from an array to a string
function tkl_make_command_line()
{
  local IFS=$' \t\r\n' # workaround for the bug in the "[@]:i" expression under the bash version lower than 4.1
  tkl_make_command_line_ex "$1" "$2" '' '' "${@:3}"
}

function tkl_make_command_line_ex()
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

  local Args
  Args=("$@")

  local CommandLine=""
  local AlwaysQuoting=0

  [[ "${EscapeFlags//a/}" != "$EscapeFlags" ]] && AlwaysQuoting=1

  local arg
  local i=0

  case "$EscapeType" in
    0)
      for arg in "${Args[@]}"; do
        [[ -n "$PredicatePrefixFunc" ]] && "$PredicatePrefixFunc" CommandLine $i "$arg"
        tkl_escape_string "$arg" "$EscapeChars" 0
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
      for arg in "${Args[@]}"; do
        [[ -n "$PredicatePrefixFunc" ]] && "$PredicatePrefixFunc" CommandLine $i "$arg"
        tkl_escape_string "$arg" "$EscapeChars" 1
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
      for arg in "${Args[@]}"; do
        [[ -n "$PredicatePrefixFunc" ]] && "$PredicatePrefixFunc" CommandLine $i "$arg"
        tkl_escape_string "$arg" "$EscapeChars" 2
        tkl_escape_string "$RETURN_VALUE" '' 0
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

function tkl_init_project_log()
{
  [[ -n "${PROJECT_LOG_ROOT+x}" ]] || tkl_abort 255 "${FUNCNAME[0]}: error: PROJECT_LOG_ROOT global variable must be defined."

  # date time request base on: https://stackoverflow.com/questions/1401482/yyyy-mm-dd-format-date-in-shell-script/1401495#1401495
  #

  tkl_declare_global PROJECT_LOG_FILE_NAME_SUFFIX

  # RANDOM instead of milliseconds
  case $BASH_VERSION in
    # < 4.2
    [123].* | 4.[01] | 4.0* | 4.1[^0-9]*)
      PROJECT_LOG_FILE_NAME_SUFFIX=$(date "+%Y'%m'%d_%H'%M'%S''")$(( RANDOM % 1000 ))
      ;;
    # >= 4.2
    *)
      printf -v PROJECT_LOG_FILE_NAME_SUFFIX "%(%Y'%m'%d_%H'%M'%S'')T$(( RANDOM % 1000 ))" -1
      ;;
  esac

  tkl_declare_global PROJECT_LOG_DIR  "$PROJECT_LOG_ROOT/$PROJECT_LOG_FILE_NAME_SUFFIX.${BASH_SOURCE_FILE_NAME%[.]*}"
  tkl_declare_global PROJECT_LOG_FILE "$PROJECT_LOG_DIR/${PROJECT_LOG_FILE_NAME_SUFFIX}.${BASH_SOURCE_FILE_NAME%[.]*}.log"

  [[ ! -e "$PROJECT_LOG_DIR" ]] && { mkdir -p "$PROJECT_LOG_DIR" || tkl_abort 255; }
}

function tkl_exec_project_logging()
{
  [[ -z "$NEST_LVL" ]] && tkl_declare_global NEST_LVL 0

  # no local logging if nested call
  (( ! IMPL_MODE && ! NEST_LVL )) && {
    tkl_init_project_log

    export IMPL_MODE=1
    exec 3>&1 4>&2
    tkl_push_trap 'exec 2>&4 1>&3' EXIT

    # stdout+stderr redirection into the same log file with handles restore
    {
    {
    {
      exec "${BASH_SOURCE_CMD_LINE_ARR[@]}" 2>&1 1>&8
    } | tee -a "$PROJECT_LOG_FILE" 1>&9
    } 8>&1 | tee -a "$PROJECT_LOG_FILE"
    } 9>&2

    tkl_exit
  }

  (( NEST_LVL++ ))
}
