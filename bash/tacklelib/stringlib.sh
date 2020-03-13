#!/bin/bash

# Bash string library, supports common string functions.

# Script can be ONLY included by "source" command.
if [[ -n "$BASH" && (-z "$BASH_LINENO" || BASH_LINENO[0] -gt 0) && (-z "$SOURCE_TACKLELIB_STRINGLIB_SH" || SOURCE_TACKLELIB_STRINGLIB_SH -eq 0) ]]; then

SOURCE_TACKLELIB_STRINGLIB_SH=1 # including guard

source '/bin/bash_entry'

tkl_include 'baselib.sh'
tkl_include 'traplib.sh'

# WARNING: this implementation may be slow!
function tkl_compare_strings()
{
  local Flags="$3"
  if [[ -n "$Flags" && "${Flags:0:1}" != '-' ]]; then
    Flags=''
  fi

  local oldShopt=""
  function tkl_local_return_impl()
  {
    [[ -n "$oldShopt" ]] && eval $oldShopt
    tkl_delete_this_func
  }

  tkl_make_func_unique_copy tkl_local_return_impl
  tkl_delete_func tkl_local_return_impl

  # override RETURN with other traps restore
  tkl_push_trap "eval $RETURN_VALUE" RETURN || return 253

  oldShopt=$(shopt -p nocasematch) # Read state before change it

  if [[ "${Flags//i/}" == "$Flags" ]]; then # case matching
    if [[ "$oldShopt" != 'shopt -u nocasematch' ]]; then
      shopt -u nocasematch
    else
      oldShopt=''
    fi
  else # nocase matching
    if [[ "$oldShopt" != 'shopt -s nocasematch' ]]; then
      shopt -s nocasematch
    else
      oldShopt=''
    fi
  fi

  [[ "$1" == "$2" ]] && return 0
  [[ "$1" < "$2" ]] && return 1

  return 255
}

# WARNING: this implementation is slow!
function tkl_to_lower_case()
{
  # drop return value
  RETURN_VALUE=""

  local String="$1"
  local StringLen="${#String}"
  local ch

  local oldShopt=""
  function tkl_local_return_impl()
  {
    [[ -n "$oldShopt" ]] && eval $oldShopt
    tkl_delete_this_func
  }

  tkl_make_func_unique_copy tkl_local_return_impl
  tkl_delete_func tkl_local_return_impl

  # override RETURN with other traps restore
  tkl_push_trap "eval $RETURN_VALUE" RETURN || return 253

  oldShopt="$(shopt -p nocasematch)" # Read state before change it

  if [[ "$oldShopt" != 'shopt -u nocasematch' ]]; then # case matching
    shopt -u nocasematch
  else
    oldShopt=''
  fi

  local i
  local j
  for (( i=0; i < StringLen; i++ )); do
    ch="${String:$i:1}"
    case "$ch" in
      [A-Z])
        printf -v j %d "'$ch"
        j="$(( j+32 ))"
        RETURN_VALUE="$RETURN_VALUE$(printf "\\$(printf %o $j)")"
        ;;

      *)
        RETURN_VALUE="$RETURN_VALUE$ch"
        ;;
    esac
  done
}

function tkl_make_command_line()
{
  local IFS=$' \t\r\n' # workaround for the bug in the "[@]:i" expression under the bash version lower than 4.1
  tkl_make_command_line_ex "$1" "$2" '' '' "${@:3}"
}

function tkl_make_command_line_ex()
{
  # drop return value
  RETURN_VALUE=''

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
    EscapeFlags=''
  else
    EscapeType="${EscapeType%%:*}"
  fi

  [[ -z "$EscapeType" ]] && EscapeType=0

  shift 4

  local IFS=$' \t\r\n'

  local Args
  Args=("$@")

  local CommandLine=''
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

fi
