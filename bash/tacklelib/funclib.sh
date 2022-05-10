#!/bin/bash

# Script library to support function object.

# Script can be ONLY included by "source" command.
[[ -z "$BASH" || (-n "$BASH_LINENO" && BASH_LINENO[0] -le 0) || (-n "$SOURCE_TACKLELIB_FUNCLIB_SH" && SOURCE_TACKLELIB_FUNCLIB_SH -ne 0) ]] && return

SOURCE_TACKLELIB_FUNCLIB_SH=1 # including guard

if [[ -z "$SOURCE_TACKLELIB_BASH_TACKLELIB_SH" || SOURCE_TACKLELIB_BASH_TACKLELIB_SH -eq 0 ]]; then
  echo."$0: error: \`bash_tacklelib\` must be included explicitly."
  exit 255
fi >&2

tkl_include_or_abort 'baselib.sh'
tkl_include_or_abort 'hashlib.sh'

function tkl_get_func_decl()
{
  local FuncName="$1" # has to be declared

  # drop return value
  RETURN_VALUE=''

  [[ -z "$FuncName" ]] && return 1

  local FuncDecl
  FuncDecl="$(declare -f "$FuncName")" || return 2
  [[ -z "$FuncDecl" ]] && return 3

  RETURN_VALUE="$FuncDecl"

  return 0
}

function tkl_get_func_decls()
{
  # drop return values
  RETURN_VALUES=()

  local FuncName
  local NumFuncs=0
  local i=0
  for FuncName in "$@"; do
    tkl_get_func_decl "$FuncName" &&
    {
      RETURN_VALUES[i++]="$RETURN_VALUE"
      (( NumFuncs++ ))
    }
  done

  (( NumFuncs )) && return 0

  return 1
}

function tkl_make_func_copy()
{
  local Flags="$1"
  if [[ "${Flags:0:1}" == '-' ]]; then
    shift
  else
    Flags=''
  fi
  local FuncName="$1"       # has to be declared
  local NewFuncName="$2"    # could not be declared
  local SuffixCmd="$3"      # command added to the end of new function

  [[-z "$NewFuncName" ]] && return 1
  tkl_get_func_decl "$FuncName" || return 2
  tkl_make_func_copy_ex "$Flags" "$RETURN_VALUE" "$NewFuncName" "$SuffixCmd" || return 3

  return 0
}

function tkl_make_func_copy_ex()
{
  local Flags="$1"
  local FuncDecl="$2"
  local NewFuncName="$3"    # could not be declared
  local SuffixCmd="$4"      # command added to the end of new function

  if [[ "${Flags//f/}" == "$Flags" ]]; then
    # new function should not exist
    local NewFuncDecl
    NewFuncDecl="$(declare -f "$NewFuncName")" && return 1
    [[ -n "$NewFuncDecl" ]] && return 2
  fi

  # replace function name
  local FuncEscapedDecl="${FuncDecl#*()}"

  # escape function declaration string
  FuncEscapedDecl="${FuncEscapedDecl//\\/\\\\}"

  (( ${#SuffixCmd} )) && FuncEscapedDecl="${FuncEscapedDecl%\}*}"$'\n'"$SuffixCmd"$'\n'"}"

  # make new function
  eval function "$NewFuncName()" "$FuncEscapedDecl"

  RETURN_VALUE="$NewFuncName"

  return 0
}

function tkl_delete_func()
{
  local FuncName="$1" # has to be declared

  [[ -z "$FuncName" ]] && return 2

  declare -f "$FuncName" > /dev/null &&
  {
    unset -f "$FuncName"
    return 0
  }

  return 1
}

# deletes current function implementation
function tkl_delete_this_func()
{
  local FuncName="${FUNCNAME[1]}"

  if [[ -n "$FuncName" ]]; then
    unset -f $FuncName
    return 0
  fi

  return 1
}

# The same as tkl_make_func_copy but adds to the function name a unique
# indentifier constructed from the value returned by the function
# HashFunctionBodyAsToken and external identifier prefix/suffix if passed to the
# function.
function tkl_make_func_unique_copy()
{
  local Flags="$1"
  if [[ "${Flags:0:1}" == '-' ]]; then
    shift
  else
    Flags=''
  fi
  local FuncName="$1"
  local NewFuncName="${2:-"$FuncName"}"
  local CallCtxLevel="${3:-0}" # 0 - context of a call to this function
  local IdPrefix="$4"
  local IdSuffix="$5"
  local SuffixCmd="$6"

  tkl_get_func_decl "$FuncName" || return 1
  local FuncDecl="$RETURN_VALUE"

  if (( ${#CallCtxLevel} )); then
    tkl_get_func_call_ctx $(( CallCtxLevel + 1 )) || return 2

    tkl_get_shell_pid
    local ShellPID="${RETURN_VALUE:-65535}" # default value if fail

    tkl_make_func_copy_ex "$Flags" "$FuncDecl" "${NewFuncName}${IdPrefix:+_}${IdPrefix}_${ShellPID}_${RETURN_VALUES[0]}_${RETURN_VALUES[1]}_${RETURN_VALUES[3]}${IdSuffix:+_}${IdSuffix}" "$SuffixCmd" || return 3
  else
    tkl_make_func_copy_ex "$Flags" "$FuncDecl" "${NewFuncName}${IdPrefix:+_}${IdPrefix}${IdSuffix:+_}${IdSuffix}" "$SuffixCmd" || return 4
  fi

  return 0
}

function tkl_get_func_name()
{
  local CallNestIndex="${1:-0}" # 0 - context of call to this function

  # drop return values
  RETURN_VALUES=('' -1)

  local LineNumber=${BASH_LINENO[CallNestIndex+1]}
  if [[ -n "$LineNumber" ]]; then
    local FuncName="${FUNCNAME[CallNestIndex+1]}"
    if [[ -n "$FuncName" ]]; then
      RETURN_VALUES=("$FuncName" "$LineNumber")
      return 0
    fi
  fi

  return 1
}

function tkl_get_func_body()
{
  local FuncName="$1" # has to be declared

  # drop return value
  RETURN_VALUE=''

  tkl_get_func_decl "$FuncName" || return 1
  local FuncBody="${RETURN_VALUE#*\{}"

  FuncBody="${FuncBody#*[$'\r\n']}"
  FuncBody="${FuncBody%\}*}"
  RETURN_VALUE="${FuncBody%[$'\r\n']*}"

  return 0
}

# from top of stack to the begin
function tkl_find_func_last_call()
{
  local FuncNames
  FuncNames=("$@")

  # drop return values
  RETURN_VALUES=(-1 $(( NumFuncs-1 )) )

  local FuncName
  local StackFuncName
  local NumFuncs=${#FUNCNAME[@]}
  local i
  for (( i=1; i < NumFuncs; i++ )); do
    StackFuncName="${FUNCNAME[i]}"
    for FuncName in "${FuncNames[@]}"; do
      if [[ "${StackFuncName#$FuncName}" != "$StackFuncName" ]]; then
        RETURN_VALUES=( $(( NumFuncs-i-1 )) $(( NumFuncs-1 )) ) # from stack begin
        return 0
      fi
    done
  done

  return 1
}

# from begin of stack to the top
function tkl_find_func_first_call()
{
  local FuncNames
  FuncNames=("$@")

  local NumFuncs=${#FUNCNAME[@]}

  # drop return values
  RETURN_VALUES=(-1 $((NumFuncs-1)) )

  local FuncName
  local StackFuncName
  local NumFuncs=${#FUNCNAME[@]}
  local i
  for (( i=NumFuncs; --i >= 1; )); do
    StackFuncName="${FUNCNAME[i]}"
    for FuncName in "${FuncNames[@]}"; do
      if [[ "${StackFuncName#$FuncName}" != "$StackFuncName" ]]; then
        RETURN_VALUES=( $(( NumFuncs-i-1 )) $(( NumFuncs-1 )) ) # from stack begin
        return 0
      fi
    done
  done

  return 1
}

function tkl_get_func_call_ctx()
{
  local CtxLevel="$1" # 0 - context of a call to this function

  # the join character should be not a character from function name token!
  tkl_join_array FUNCNAME '|' $(( CtxLevel + 2 )) && tkl_crc32 "${RETURN_VALUES[1]}" && tkl_dec_to_hex "$RETURN_VALUE" ||
  {
    # drop return values
    RETURN_VALUES=(0 '' 0 '' 0)
    return 1
  }

  local FuncsStackCallNamesHashToken="$RETURN_VALUE"
  local FuncsStackCallNames="${RETURN_VALUES[1]}"
  local FuncsStackCallNumNames="${RETURN_VALUES[0]}"

  tkl_join_array BASH_LINENO '|' $(( CtxLevel + 2 )) && tkl_crc32 "${RETURN_VALUES[1]}" && tkl_dec_to_hex "$RETURN_VALUE" ||
  {
    # drop return values
    RETURN_VALUES=(0 '' 0 '' 0)
    return 2
  }

  local FuncsStackCallLinesHashToken="$RETURN_VALUE"
  local FuncsStackCallLines="${RETURN_VALUES[1]}"

  RETURN_VALUES=(
    "$FuncsStackCallNumNames"
    "$FuncsStackCallNamesHashToken" "$FuncsStackCallNames"
    "$FuncsStackCallLinesHashToken" "$FuncsStackCallLines"
  )

  return 0
}
