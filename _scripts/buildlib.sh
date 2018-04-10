#!/bin/bash

# Script can be ONLY included by "source" command.
if [[ -n "$BASH" && (-z "$BASH_LINENO" || ${BASH_LINENO[0]} -gt 0) ]] && (( ! ${#SOURCE_BUILDLIB_SH} )); then 

SOURCE_BUILDLIB_SH=1 # including guard

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
  let NEST_LVL-=1

  [[ $NEST_LVL -eq 0 ]] && Pause

  if [[ $# -eq 0 ]]; then
    exit $LastError
  else
    exit $@
  fi
}

function Call()
{
  echo ">$@"
  eval "$@"
  LastError=$?
}

function SetError()
{
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
      if [[ -z "${args[i]%%-*}" ]]; then
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

function MakeDir()
{
  local flag_args=()

  ReadCommandLineFlags flag_args "$@"
  (( ${#flag_args} )) && shift ${#flag_args}

  local arg
  for arg in "$@"; do
    [[ ! -f "$arg" ]] && {
      MakeCommandLine '' 1 "$arg"
      echo ">mkdir ${flag_args[@]} $RETURN_VALUE"
      mkdir ${flag_args[@]} "$arg" || return $?
    }
  done

  return $?
}

function MoveFile()
{
  local flag_args=()

  ReadCommandLineFlags flag_args "$@"
  (( ${#flag_args} )) && shift ${#flag_args}

  local FILE_IN="$1"
  shift

  local file
  local IFS=$' \t\r\n'

  for file in `find . -type f -name "$FILE_IN" -o -type l -name "$FILE_IN"`; do
    MakeCommandLine '' 1 "$file" "$@"
    echo ">mv ${flag_args[@]} $RETURN_VALUE"
    mv ${flag_args[@]} "$file" "$@" || return $?
  done

  return 0
}

function JoinArgs()
{
  local IFS="$1"
  shift
  RETURN_VALUE="$*"
}

function Configure()
{
  export CMAKE_BUILD_TYPE
  export CMAKE_BUILD_ROOT="$CMAKE_OUTPUT_ROOT/build/$CMAKE_BUILD_TYPE"
  export CMAKE_BIN_ROOT="$CMAKE_OUTPUT_ROOT/bin/$CMAKE_BUILD_TYPE"
  export CMAKE_LIB_ROOT="$CMAKE_OUTPUT_ROOT/lib/$CMAKE_BUILD_TYPE"
  export CMAKE_INSTALL_ROOT="$CMAKE_OUTPUT_ROOT/install"
  export CMAKE_CPACK_ROOT="$CMAKE_OUTPUT_ROOT/pack/$CMAKE_BUILD_TYPE"

  MakeDir -p "$CMAKE_BUILD_ROOT"
  MakeDir -p "$CMAKE_BIN_ROOT"
  MakeDir -p "$CMAKE_LIB_ROOT"
  MakeDir -p "$CMAKE_CPACK_ROOT"

  CONFIGURE_FILE_IN="`/bin/readlink -f "$ScriptDirPath/../$ScriptFileName.in"`"

  MakeCommandArgumentsFromFile -e "$CONFIGURE_FILE_IN"

  CMAKE_CMD_LINE=("${RETURN_VALUE[@]}")

  Pushd "$CMAKE_BUILD_ROOT" && {
    Call cmake "${CMAKE_CMD_LINE[@]}" || { Popd; return $LastError; }
    Popd
  }

  return $LastError
}

function Build()
{
  export CMAKE_BUILD_TYPE
  export CMAKE_BUILD_ROOT="$CMAKE_OUTPUT_ROOT/build/$CMAKE_BUILD_TYPE"

  MakeDir -p "$CMAKE_BUILD_ROOT"

  Pushd "$CMAKE_BUILD_ROOT" && {
    Call cmake --build . --config $CMAKE_BUILD_TYPE --target all || { Popd; return $LastError; }
    Popd
  }

  return $LastError
}

function Install()
{
  export CMAKE_BUILD_TYPE
  export CMAKE_BUILD_ROOT="$CMAKE_OUTPUT_ROOT/build/$CMAKE_BUILD_TYPE"

  MakeDir -p "$CMAKE_BUILD_ROOT"

  Pushd "$CMAKE_BUILD_ROOT" && {
    Call cmake --build . --config $CMAKE_BUILD_TYPE --target install || { Popd; return $LastError; }
    Popd
  }

  return $LastError
}

function PostInstall()
{
  export CMAKE_BUILD_TYPE
  export CMAKE_INSTALL_ROOT="$CMAKE_OUTPUT_ROOT/install/$CMAKE_BUILD_TYPE"

  MakeDir -p "$CMAKE_BUILD_ROOT"

  Pushd "$CMAKE_INSTALL_ROOT" && {
    PostInstallImpl || { Popd; return $LastError; }
    Popd
  }

  return $LastError
}

function PostInstallImpl()
{
  local FileDepsList=("*.so" "*.so.*" "*.a" "*.a.*")

  # collect system dependencies
  JoinArgs : "${FileDepsList[@]}"
  Call "$PROJECT_ROOT/_scripts/deploy/collect_ldd_deps.sh" . "$RETURN_VALUE" deps.lst .

  # create symbol links
  Call "$PROJECT_ROOT/_scripts/deploy/create_links.sh" .

  # move all `.so` and `.a` files into `/lib` subdirectory
  MakeDir "lib"

  local file
  local IFS=$' \t\r\n'

  for file in ${FileDepsList}; do
    MoveFile "${file}" lib/
  done
}

function Pack()
{
  export CMAKE_BUILD_TYPE
  export CMAKE_BUILD_ROOT="$CMAKE_OUTPUT_ROOT/build/$CMAKE_BUILD_TYPE"

  export PATH="$PATH%:$NSIS_INSTALL_ROOT"

  MakeDir -p "$CMAKE_BUILD_ROOT"

  Pushd "$CMAKE_BUILD_ROOT" && {
    Call cmake --build . --config $CMAKE_BUILD_TYPE --target bundle || { Popd; return $LastError; }
    Popd
  }

  return $LastError
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

function EscapeString()
{
  # drop return value
  RETURN_VALUE=""

  # (Required) String which would be escaped.
  local String="$1"
  # (Optional) Set of characters in string which are gonna be escaped.
  local EscapeChars="$2"
  # (Optional) Type of escaping:
  #   0 - String will be quoted by the " character, so escape any character from
  #       "EscapeChars" by the \ character.
  #   1 - String will be quoted by the ' character, so the ' character should be
  #       escaped by the \' sequance. The "EscapeChars" variable doesn't used in this case.
  #   2 - String will be used in the cmd.exe shell, so quote any character from
  #       the "EscapeChars" variable by the ^ character.
  local EscapeType="${3:-0}"

  if [[ -z "$String" ]]; then
    RETURN_VALUE="$String"
    return 1
  fi

  if [[ -z "$EscapeChars" ]]; then
    case $EscapeType in
      0) EscapeChars='$!&|\`"' ;;
      2) EscapeChars='^?*&|<>()"' ;;
    esac
  fi

  local EscapedString=""
  local StringCharEscapeOffset=-1
  local i
  for (( i=0; i<${#String}; i++ )); do
    local StringChar="${String:$i:1}"
    case $EscapeType in
      0)
        FindChar "$EscapeChars" "$StringChar"
        StringCharEscapeOffset="$RETURN_VALUE"
        if (( StringCharEscapeOffset < 0 )); then
          EscapedString="$EscapedString$StringChar"
        else
          EscapedString="$EscapedString\\$StringChar"
        fi
      ;;
      1)
        if [[ "$StringChar" != "'" ]]; then
          EscapedString="$EscapedString$StringChar"
        else
          EscapedString="$EscapedString'\\''"
        fi
      ;;
      *)
        FindChar "$EscapeChars" "$StringChar"
        StringCharEscapeOffset="$RETURN_VALUE"
        if (( StringCharEscapeOffset >= 0 )); then
          EscapedString="$EscapedString^"
        fi
        EscapedString="$EscapedString$StringChar"
      ;;
    esac
  done

  [[ -n "$EscapedString" ]] || return 2

  RETURN_VALUE="$EscapedString"

  return 0
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

  if [[ "$Flags" != "-" && "${Flags#-*}" != "$Flags" ]]; then
    [[ "${Flags//e/}" != "$Flags" ]] && DoEval=1
    [[ "${Flags//q/}" != "$Flags" ]] && AlwaysQuoting=1
  fi

  if [[ "$FilePath" != '-' ]]; then
    FilePath="`/bin/readlink -m "$FilePath"`"
    [[ -f "$FilePath" ]] || return 1
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
        if (( AlwaysQuoting )) || [[ "${ConfigLine//[ $'\t\r\n']/}" != "$ConfigLine" ]]; then
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

  local IFS=$' \t\n'

  local Args
  Args=("$@")

  local CommandLine=""
  local AlwaysQuoting=1

  [[ "${EscapeFlags//a/}" != "$EscapeFlags" ]] && AlwaysQuoting=0

  local arg
  local i=0

  case "$EscapeType" in
    0)
      for arg in "${Args[@]}"; do
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
      for arg in "${Args[@]}"; do
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
      for arg in "${Args[@]}"; do
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
