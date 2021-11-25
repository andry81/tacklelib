#!/bin/bash

# Script library to support basic shell operations.

# Short keyword's descriptions:
#  item   - value which passed as string in a function argument.
#  array  - array of not unique values which passed as array name in a function argument.
#  list   - list of not unique values which passed as string in a function argument.
#  args   - list of not unique values which passed in function arguments ($@).
#  uarray - array of unique values which passed as array name in a function argument.
#  ulist  - list of unique values which passed as string in a function argument.
#  pitem  - wildcard pattern value which passed as string in a function argument.
#  parray - array of not unique wildcard pattern values which passed as array name in a function argument.
#  plist  - list of not unique wildcard pattern values which passed as string in a function argument.
#  pargs  - list of not unique wildcard pattern items which passed in function arguments ($@).

# Script can be ONLY included by "source" command.
[[ -z "$BASH" || (-n "$BASH_LINENO" && BASH_LINENO[0] -le 0) || (-n "$SOURCE_TACKLELIB_BASELIB_SH" && SOURCE_TACKLELIB_BASELIB_SH -ne 0) ]] && return

SOURCE_TACKLELIB_BASELIB_SH=1 # including guard

if [[ -z "$SOURCE_TACKLELIB_BASH_TACKLELIB_SH" || SOURCE_TACKLELIB_BASH_TACKLELIB_SH -eq 0 ]]; then
  echo."$0: error: \`bash_tacklelib\` must be included explicitly."
  exit 255
fi >&2

function tkl_enable_nocase_match()
{
  RETURN_VALUE=$(shopt -p nocasematch) && # Read state before change
  if [[ "$RETURN_VALUE" != 'shopt -s nocasematch' ]]; then
    shopt -s nocasematch
    return 0
  fi

  RETURN_VALUE=''

  return 1
}

function tkl_disable_nocase_match()
{
  RETURN_VALUE=$(shopt -p nocasematch) && # Read state before change
  if [[ "$RETURN_VALUE" != 'shopt -u nocasematch' ]]; then
    shopt -u nocasematch
    return 0
  fi

  RETURN_VALUE=''

  return 1
}

# Function-wrapper over the shift command to pass into the shift the correct
# number of parameters to offset.
function tkl_get_shift_offset()
{
  local maxOffset="${1:-0}"
  if (( maxOffset )); then
    shift
  else
    return 0
  fi

  local numArgs=$#
  (( numArgs >= maxOffset )) && return $maxOffset

  return $numArgs
}

function tkl_is_equal_string_arrays()
{
  eval declare "ArraySize1=\${#$1[@]}"
  eval declare "ArraySize2=\${#$2[@]}"

  if (( ArraySize1 != ArraySize2 )); then
    if (( ArraySize1 < ArraySize2 )); then
      return 1
    else
      return -1
    fi
  fi

  local i
  for (( i=0; i < ArraySize1; i++ )); do
    if eval "[[ \"\${$1[i]}\" < \"\${$2[i]}\" ]]"; then
      return 1
    elif eval "[[ \"\${$2[i]}\" < \"\${$1[i]}\" ]]"; then
      return -1
    fi
  done

  return 0
}

function tkl_is_equal_integer_arrays()
{
  eval declare "ArraySize1=\${#$1[@]}"
  eval declare "ArraySize2=\${#$2[@]}"

  if (( ArraySize1 != ArraySize2 )); then
    if (( ArraySize1 < ArraySize2 )); then
      return 1
    else
      return -1
    fi
  fi

  local i
  for (( i=0; i < ArraySize1; i++ )); do
    if eval "(( $1[i]} < $2[i] ))"; then
      return 1
    elif eval "(( $2[i] < $1[i] ))"; then
      return -1
    fi
  done

  return 0
}

function tkl_reverse_array()
{
  local InArrName="$1"
  local OutArrName="$2"
  local InArrSize
  local i
  local j

  eval "InArrSize=\${#$InArrName[@]}"

  tkl_declare_array $OutArrName # CAUTION: MUST BE after all local variables
  for (( i=InArrSize, j=0; --i >= 0; j++ )); do
    eval "$OutArrName[j]=\"\${$InArrName[i]}\""
  done
}

function tkl_remove_array_from_uarray()
{
  # by default: workaround for the bug in the "[@]:i" expression under the bash version lower than 4.1
  local IFS="${3:-$' \t\r\n'}"

  local i
  local j
  local isFound
  local item1
  local item2
 
  eval declare "ArrayFromSize=\${#$1[@]}"
  eval declare "UArrayToSize=\${#$2[@]}"

  (( ! UArrayToSize )) && return
  for (( i=0; i < ArrayFromSize; i++ )); do
    eval "item1=\"\${$1[i]}\""
    isFound=0
    for (( j=0; j < UArrayToSize; j++ )); do
      eval "item2=\"\${$2[j]}\""
      if [[ "$item1" == "$item2" ]]; then
        isFound=1
        break
      fi
    done
    if (( isFound )); then
      # remove it from the array
      eval "$2=(\"\${$2[@]:0:j}\" \"\${$2[@]:j+1}\")"
      (( UArrayToSize-- ))
    fi

    (( ! UArrayToSize )) && break
  done
}

function tkl_remove_item_from_uarray()
{
  local IFS=$' \t\r\n' # workaround for the bug in the "[@]:i" expression under the bash version lower than 4.1

  local i
  local item
  eval declare "UArraySize=\${#$1[@]}"
  for (( i=0; i < UArraySize; i++ )); do
    eval "item=\"\${$1[i]}\""
    if [[ "$item" == "$2" ]]; then
      # remove it from the array
      eval "$1=(\"\${$1[@]:0:\$i}\" \"\${$1[@]:\$i+1}\")"
      return 0
    fi
  done

  return 1
}

function tkl_remove_pargs_from_array()
{
  # drop return value
  RETURN_VALUE=0

  local ArrayName="$1"
  shift

  local PArgsArr
  PArgsArr=("$@")

  local i
  local j
  local item

  local IFS=$' \t\r\n' # workaround for the bug in the "[@]:i" expression under the bash version lower than 4.1

  eval declare "ArraySize=\${#$ArrayName[@]}"
  local PArgsSize="${#PArgsArr}"
  for (( i=0; i < PArgsSize; i++ )); do
    for (( j=0; j < ArraySize; )); do
      eval "item=\"\${$ArrayName[j]}\""
      case "$item" in
        ${PArgsArr[i]})
          # remove it from the array
          eval "$ArrayName=(\"\${$ArrayName[@]:0:\$j}\" \"\${$ArrayName[@]:\$j+1}\")"
          (( RETURN_VALUE++ ))
          ;;
        *) (( i++ )) ;;
      esac
    done
  done

  return 1
}

# instead of a remove does clear to empty string
function tkl_clear_pargs_from_array()
{
  # drop return value
  RETURN_VALUE=0

  local ArrayName="$1"
  shift

  local PArgsArr
  PArgsArr=("$@")

  local i
  local j
  local item

  local IFS=$' \t\r\n' # workaround for the bug in the "[@]:i" expression under the bash version lower than 4.1

  eval declare "ArraySize=\${#$ArrayName[@]}"
  local PArgsSize="${#PArgsArr[@]}"
  for (( i=0; i < PArgsSize; i++ )); do
    [[ -z "${PArgsArr[i]}" ]] && continue
    for (( j=0; j < ArraySize; j++ )); do
      eval "item=\"\${$ArrayName[j]}\""
      [[ -z "$item" ]] && continue
      case "$item" in
        ${PArgsArr[i]})
          # clear it in the array
          eval "$ArrayName[j]=''"
          (( RETURN_VALUE++ ))
          ;;
      esac
    done
  done
}

function tkl_append_item_to_uarray()
{
  # drop return value
  RETURN_VALUE=-1

  local i
  local item

  # by default: workaround for the bug in the "[@]:i" expression under the bash version lower than 4.1
  local IFS="${3:-$' \t\r\n'}"

  eval declare "UArraySize=\${#$1[@]}"
  for (( i=0; i < UArraySize; i++ )); do
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

function tkl_assign_item_to_uarray()
{
  # drop return value
  RETURN_VALUE=-1

  local AssignPredicateFunc="$3"

  [[ -z "$AssignPredicateFunc" ]] && return 2

  local i
  local item

  # by default: workaround for the bug in the "[@]:i" expression under the bash version lower than 4.1
  local IFS="${4:-$' \t\r\n'}"

  eval declare "UArraySize=\${#$1[@]}"
  for (( i=0; i < UArraySize; i++ )); do
    eval "item=\"\${$1[i]}\""
    if "$AssignPredicateFunc" $i "$item" "$2"; then
      RETURN_VALUE=$i
      return 1
    fi
  done

  eval "$1[UArraySize]=\"\$2\""

  RETURN_VALUE=$UArraySize

  return 0
}

function tkl_append_list_to_array()
{
  # by default: workaround for the bug in the "[@]:i" expression under the bash version lower than 4.1
  local IFS="${3:-$' \t\r\n'}"

  local ArrayFrom=($1)
  eval "$2=(\"\${$2[@]}\" \"\${ArrayFrom[@]}\")"
}

function tkl_append_list_to_uarray()
{
  # by default: workaround for the bug in the "[@]:i" expression under the bash version lower than 4.1
  local IFS="${3:-$' \t\r\n'}"

  local i
  local j
  local isFound
  local item1
  local item2
  local ArrayFrom=($1)
  local ArrayFromSize="${#ArrayFrom[@]}"

  eval declare "UArrayToSize=\${#$2[@]}"
  for (( i=0; i < ArrayFromSize; i++ )); do
    item1="${ArrayFrom[i]}"
    isFound=0
    for (( j=0; j < UArrayToSize; j++ )); do
      eval "item2=\"\${$2[j]}\""
      if [[ "$item1" == "$item2" ]]; then
        isFound=1
        break
      fi
    done
    if (( ! isFound )); then
      eval "$2[UArrayToSize]=\"\$item1\""
      (( UArrayToSize++ ))
    fi
  done
}

function tkl_append_ulist_to_uarray()
{
  # by default: workaround for the bug in the "[@]:i" expression under the bash version lower than 4.1
  local IFS="${3:-$' \t\r\n'}"

  local i
  local j
  local isFound
  local item1
  local item2
  local ArrayFrom=($1)
  local ArrayFromSize="${#ArrayFrom[@]}"

  eval declare "UArrayToSize=\${#$2[@]}"
  if (( ! UArrayToSize )); then
    eval "$2=(\"\${ArrayFrom[@]}\")"
    return
  fi
  for (( i=0; i < ArrayFromSize; i++ )); do
    item1="${ArrayFrom[i]}"
    isFound=0
    for (( j=0; j < UArrayToSize; j++ )); do
      eval "item2=\"\${$2[j]}\""
      if [[ "$item1" == "$item2" ]]; then
        isFound=1
        break
      fi
    done
    if (( ! isFound )); then
      eval "$2[UArrayToSize]=\"\$item1\""
      (( UArrayToSize++ ))
    fi
  done
}

function tkl_append_array_to_uarray()
{
  # by default: workaround for the bug in the "[@]:i" expression under the bash version lower than 4.1
  local IFS="${3:-$' \t\r\n'}"

  local i
  local j
  local isFound
  local item1
  local item2

  eval declare "ArrayFromSize=\${#$1[@]}"
  eval declare "UArrayToSize=\${#$2[@]}"
  for (( i=0; i < ArrayFromSize; i++ )); do
    eval "item1=\"\${$1[i]}\""
    isFound=0
    for (( j=0; j < UArrayToSize; j++ )); do
      eval "item2=\"\${$2[j]}\""
      if [[ "$item1" == "$item2" ]]; then
        isFound=1
        break
      fi
    done
    if (( ! isFound )); then
      eval "$2[UArrayToSize]=\"\$item1\""
      (( UArrayToSize++ ))
    fi
  done
}

function tkl_append_uarray_to_uarray()
{
  # by default: workaround for the bug in the "[@]:i" expression under the bash version lower than 4.1
  local IFS="${3:-$' \t\r\n'}"

  local i
  local j
  local isFound
  local item1
  local item2

  eval declare "UArrayToSize=\${#$1[@]}"
  eval declare "UArrayFromSize=\${#$2[@]}"
  if (( ! UArrayToSize )); then
    eval "$1=(\"\${$2[@]}\")"
    return
  fi
  for (( j=0; j < UArrayFromSize; j++ )); do
    eval "item2=\"\${$2[j]}\""
    isFound=0
    for (( i=0; i < UArrayToSize; i++ )); do
      eval "item1=\"\${$1[i]}\""
      if [[ "$item1" == "$item2" ]]; then
        isFound=1
        break
      fi
    done
    if (( ! isFound )); then
      eval "$1[UArrayToSize]=\"\$item2\""
      (( UArrayToSize++ ))
    fi
  done
}

function tkl_assign_uarray_to_uarray()
{
  local FirstPredicateFunc="$3"
  local SecondPredicateFunc="$4"
  local AssignPredicateFunc="$5"

  [[ -z "$FirstPredicateFunc" ]] && return 1
  [[ -z "$SecondPredicateFunc" ]] && return 2
  [[ -z "$AssignPredicateFunc" ]] && return 3

  # by default: workaround for the bug in the "[@]:i" expression under the bash version lower than 4.1
  local IFS="${6:-$' \t\r\n'}"

  local i
  local j
  local isFound
  local item1
  local item2
  eval declare "UArrayToSize=\${#$1[@]}"
  eval declare "UArrayFromSize=\${#$2[@]}"

  for (( j=0; j < UArrayFromSize; j++ )); do
    eval "item2=\"\${$2[j]}\""
    if "$FirstPredicateFunc" "$1" "$2" $j "$item2"; then
      isFound=0
      for (( i=0; i < UArrayToSize; i++ )); do
        eval "item1=\"\${$1[i]}\""
        if "$SecondPredicateFunc" "$1" "$2" $i $j "$item1" "$item2"; then
          isFound=1
          break
        fi
      done
      if (( ! isFound )); then
        "$AssignPredicateFunc" "$1" "$2" $i $j "$item2"
        (( UArrayToSize += $? ))
      fi
    fi
  done

  return 0
}

function tkl_append_array_to_array()
{
  # by default: workaround for the bug in the "[@]:i" expression under the bash version lower than 4.1
  local IFS="${3:-$' \t\r\n'}"

  local i

  eval declare "ArrayFromSize=\${#$1[@]}"
  eval declare "ArrayToSize=\${#$2[@]}"
  if (( ! ArrayToSize )); then
    eval "$2=(\"\${$1[@]}\")"
    return
  fi
  for (( i=0; i < ArrayFromSize; i++ )); do
    eval "$2[ArrayToSize]=\"\${$1[i]}\""
    (( ArrayToSize++ ))
  done
}

function tkl_get_time_as_string()
{
  # drop return value
  RETURN_VALUE=''

  if (( $# < 1 || ! ${1:-0} )); then
    RETURN_VALUE="0${2:-"s"}"
    return
  fi

  local TimeSecsOverall="$1"

  local TimeSecs="$TimeSecsOverall"

  local TimeMins=0
  (( TimeMins = TimeSecs/60 ))
  (( TimeSecs %= 60 ))

  local TimeHours=0
  (( TimeHours = TimeMins/60 ))
  (( TimeMins %= 60 ))

  local TimeDays=0
  (( TimeDays = TimeHours/24 ))
  (( TimeHours %= 24 ))

  local TimeString=''

  (( TimeDays )) && TimeString="$TimeString${TimeDays}${TimeDays:+" Days, "}"
  (( TimeHours )) && TimeString="$TimeString${TimeHours}${TimeHours:+"h:"}"

  local TimeMinsStr="$TimeMins"
  local TimeSecsStr="$TimeSecs"
  if (( TimeMins > 0 )); then
    (( TimeMins <= 9 )) && TimeMinsStr="0$TimeMins"
    (( ${#TimeSecs} == 1 )) && TimeSecsStr="0$TimeSecs"
  fi

  (( TimeMins )) && TimeString="$TimeString${TimeMinsStr}${TimeMins:+"m:"}"
  local TimeWord="second"
  (( TimeSecsOverall > 1 )) && TimeWord="${TimeWord}s"

  TimeString="$TimeString${TimeSecsStr}${TimeSecs:+"s"} ($TimeSecsOverall $TimeWord)"

  RETURN_VALUE="$TimeString"
}

# array of elements, where keys by even indexes and values by odd indexes
function tkl_assoc_get()
{
  # drop return value
  RETURN_VALUE=''

  local DefaultValue="$1"
  local ArrayName="$2"
  local Key="$3"

  if [[ -z "${ArrayName}" ]]; then
    [[ -n "${DefaultValue}" ]] && RETURN_VALUE="${DefaultValue}"
    return 1
  fi

  eval declare "ArraySize=\${#$ArrayName[@]}"

  local Array=()
  local i
  for (( i=0; i < ArraySize; i++ )); do
    eval Array[i]=\${$ArrayName[i]}
  done

  if (( ! ${#Array[@]} )); then
    [[ -n "${DefaultValue}" ]] && RETURN_VALUE="${DefaultValue}"
    return 2
  fi

  if [[ -z "$Key" ]]; then
    [[ -n "${DefaultValue}" ]] && RETURN_VALUE="${DefaultValue}"
    return 3
  fi

  for (( i=0; i < ${#Array[@]}; i+=2 )); do
    if [[ "${Array[i]}" == "$Key" ]]; then
      [[ -n "${Array[i+1]}" ]] && RETURN_VALUE="${Array[i+1]}"
      return 0
    fi
  done

  [[ -n "${DefaultValue}" ]] && RETURN_VALUE="${DefaultValue}"

  return 4
}

function tkl_find_array_item()
{
  local ArrayName="$1"
  local Item="$2"

  # drop return value
  RETURN_VALUE="-1"

  local ArraySize
  eval "ArraySize=\${#$ArrayName[@]}"

  local Item2
  local i
  for (( i=0; i < ArraySize; i++ )); do
    eval "Item2=\"\${$ArrayName[i]}\""
    if [[ "$Item" == "$Item2" ]]; then
      RETURN_VALUE="$i"
      return 0
    fi
  done

  return 1
}

function tkl_dec_to_hex()
{
  local value=$1
  local width=${2:-0}

  local hexChars=(0 1 2 3 4 5 6 7 8 9 a b c d e f)
  local hex
  local type=0

  # workaround for "printf %x" negative values under the bash 3.1.0
  if (( value < 0 )); then
    if (( value < 0x80000000 )); then
      type=2 # handle of negative numbers wider than 32-bit long
    else
      type=1 # handle of negative 32-bit numbers
    fi
  elif (( value > 0xffffffff )); then # handle of positive 64-bit numbers
    if (( value > 0x7fffffffffffffff )); then
      type=2
    fi
  elif (( value > 0x7fffffff )); then # handle of positive 32-bit numbers
    type=1
  fi

  if (( type == 0 )); then
    printf -v hex %x $value
  elif (( type == 1 )); then
    (( hex=value-0x7FFFFFFF-1 ))
    printf -v hex %08x $hex
    hex="${hexChars[${hex:0:1}+8]}${hex:1}"
  else
    (( hex=value-0x7FFFFFFFFFFFFFFF-1 ))
    printf -v hex %08x $hex
    hex="${hexChars[${hex:0:1}+8]}${hex:1}"
  fi

  RETURN_VALUE="${hex:-0}"

  (( width )) && tkl_zero_padding $width $RETURN_VALUE

  return 0
}

function tkl_zero_padding()
{
  local width="${1:-0}"
  local value="$2"
  local zeros="${3:-0000000000000000}"

  # workaround for the bash 3.1.0 bug for the expression "${arg:X:Y}",
  # where "Y == 0" or "Y + X >= ${#arg}"
  if (( width > ${#value} )); then
    RETURN_VALUE="${zeros:0:width-${#value}}$value"
    return 0
  fi

  RETURN_VALUE="$value"

  return 0
}

function tkl_zero_padding_from_args()
{
  # drop return values
  RETURN_VALUES=()

  local zeros="${1:-0000000000000000}"
  shift

  while (( $# )); do
    tkl_zero_padding "$1" "$2" "$zeros"
    RETURN_VALUES[${#RETURN_VALUES[@]}]="$RETURN_VALUE"
    shift 2
  done
}

# WARNING:
#   For the bash version 3.x this function only emulates the bash subshell
#   process id via the global BASH_SUBSHELL_PIDS array generated from
#   builtin variables BASH_SUBSHELL and RANDOM.
function tkl_get_shell_pid()
{
  local ParentNestIndex="${1:-0}" # 0 - self pid

  # always use the global array
  [[ -z "${BASH_SUBSHELL_PIDS[@]}" ]] && tkl_declare_global_array BASH_SUBSHELL_PIDS

  if (( BASH_VERSINFO[0] >= 4 )); then
    tkl_declare_global BASH_SUBSHELL_PIDS[BASH_SUBSHELL] $BASHPID
  else
    # this logic is not guarantee the real process id value, it's guarantee it's
    # uniqueness
    if [[ -z "${BASH_SUBSHELL_PIDS[BASH_SUBSHELL]}" ]]; then
      # allocate shell PID as random value which are not in the list
      local ShellPID
      local pid
      local IsUnique=0

      while (( ! IsUnique )); do
        let ShellPID=$RANDOM+$RANDOM
        IsUnique=1
        for pid in "${BASH_SUBSHELL_PIDS[@]}"; do
          if (( pid == ShellPID )); then
            IsUnique=0
            break
          fi
        done
      done

      BASH_SUBSHELL_PIDS[BASH_SUBSHELL]=$ShellPID
    fi
  fi

  # use BASH_SUBSHELL instead of array size because the array can has holes
  if (( ParentNestIndex >= 0 && BASH_SUBSHELL >= ParentNestIndex )); then
    RETURN_VALUE=${BASH_SUBSHELL_PIDS[BASH_SUBSHELL-ParentNestIndex]}
    return 0
  fi

  # drop return value
  RETURN_VALUE=''

  return 1
}

function tkl_safe_func_call()
{
  local IFS=$' \t\r\n' # workaround for the bug in the "[@]:i" expression under the bash version lower than 4.1

  # evaluation w/o extra local variables!
  declare -f "$1" > /dev/null &&
  {
    eval "$1" \"\${@:2}\"
    return $?
  }
  return 0
}

function tkl_safe_func_call_with_prefix()
{
  local IFS=$' \t\r\n' # workaround for the bug in the "[@]:i" expression under the bash version lower than 4.1

  # evaluation w/o extra local variables!
  declare -f "${@:2:1}" > /dev/null &&
  {
    eval "$1" # prefix
    eval "${@:2:1}" \"\${@:3}\"
    return $?
  }

  return 0
}

function tkl_safe_string_eval()
{
  local numArgs=$#
  local LastError=0

  # evaluation w/o extra local variables!
  # first argument - extra eval string
  if (( numArgs )); then
    if [[ -n "$1" ]]; then
      eval "$1"
      LastError=$?
    fi
    shift
    (( numArgs-- ))
  fi
  # next arguments - only functions
  while (( numArgs )); do
    if [[ -n "$1" ]]; then
      eval tkl_safe_func_call "$1"
      LastError=$?
    fi
    shift
    (( numArgs-- ))
  done

  return $LastError # always return error code from last call
}

function tkl_safe_strings_eval()
{
  local numArgs=$#
  local LastError=0

  #echo "SafeStringsEval: ${FUNCNAME[@]}"
  # evaluation w/o extra local variables!
  while (( numArgs )); do
    if [[ -n "$1" ]]; then
      eval "$1"
      LastError=$?
    fi
    shift
    (( numArgs-- ))
  done

  return $LastError # always return error code from last call
}

function tkl_unset()
{
  unset -v -- "$@"
}

function tkl_wait()
{
  local i
  for (( i=0; i < $1; i++ )); do
    (echo '' > /dev/null)
  done
}

function tkl_set_last_error()
{
  return ${1:-$tkl__last_error}
}

function tkl_join_array()
{
  local ArrayName="$1"
  local JoinChar="$2"
  local ArrayBegin="${3:-0}"
  local ArrayJoinSize="$4"

  # drop return values
  RETURN_VALUES=(0 '')

  (( ArrayBegin < 0 )) && return 1

  local ArraySize
  eval "ArraySize=\${#$ArrayName[@]}"
  (( ! ArraySize )) && return 2

  (( ArraySize < ArrayBegin )) && ArrayBegin=$ArraySize
  local ArrayMaxJoinSize=$(( ArraySize-ArrayBegin ))
  if [[ -z "$ArrayJoinSize" ]]; then
    ArrayJoinSize=$ArrayMaxJoinSize
  elif (( ArrayJoinSize < ArrayMaxJoinSize )); then
    ArrayMaxJoinSize=$ArrayJoinSize
  fi

  (( ArrayBegin < ArraySize )) || return 3

  local IFS="$JoinChar"
  local JoinedArray
  eval "JoinedArray=\"\${$ArrayName[*]:ArrayBegin:ArrayMaxJoinSize}\""

  RETURN_VALUES=($ArrayMaxJoinSize "$JoinedArray")

  return 0
}

function tkl_get_current_function_names_stack_trace()
{
  local out_var="${1:-RETURN_VALUE}"

  tkl_join_array FUNCNAME '|' 2
  tkl_declare "$out_var" "${RETURN_VALUES[1]}"
}
