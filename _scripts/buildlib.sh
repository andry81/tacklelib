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
  echo ">$@"
  "$@"
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

  eval "CMAKE_CMD_LINE=($RETURN_VALUE)"
  Pushd "$CMAKE_BUILD_ROOT" && {
    Call cmake "${CMAKE_CMD_LINE[@]}" || { Popd; return $LastError; }
    Popd
  }

  return $LastError
}

function ConfigureNoGen()
{
  CONFIGURE_FILE_IN="`/bin/readlink -f "$ScriptDirPath/../$ScriptFileName.in"`"

  MakeCommandArgumentsFromFile -e "$CONFIGURE_FILE_IN"

  eval "CMAKE_CMD_LINE=($RETURN_VALUE)"
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
    Call cmake --build . --config "$CMAKE_BUILD_TYPE" --target "$CMAKE_BUILD_TARGET" || { Popd; return $LastError; }
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
    Call cmake --build . --config "$CMAKE_BUILD_TYPE" --target "$CMAKE_BUILD_TARGET" || { Popd; return $LastError; }
    Popd
  }

  return $LastError
}

function PostInstall()
{
  export CMAKE_BUILD_TYPE
  export CMAKE_INSTALL_ROOT="$CMAKE_OUTPUT_ROOT/install/$CMAKE_BUILD_TYPE"

  MakeDir -p "$CMAKE_INSTALL_ROOT"

  Pushd "$CMAKE_INSTALL_ROOT" && {
    PostInstallImpl || { Popd; return $LastError; }
    Popd
  }

  return $LastError
}

function PostInstallImpl()
{
  local FileDepsList
  FileDepsList=("*.so" "*.so.*" "*.a" "*.a.*")

  local cwd="$(pwd)"
  local IFS=$' \t\r\n'

  # create application directories at first
  MakeDir _scripts _scripts/admin _scripts/deploy lib plugins plugins/platforms || return $?

  # copy Qt plugins
  Call cp -R "$QT5_ROOT/plugins/platforms/." "$cwd/plugins/platforms" || return $?

  IFS=$' \t\r\n'
  JoinArgs : "${FileDepsList[@]}"

  # collect shared object dependencies
  Call "$PROJECT_ROOT/_scripts/deploy/collect_ldd_deps.sh" ".:./plugins/platforms" "$RETURN_VALUE" ".:./plugins/platforms:$QT5_ROOT/lib" deps.lst . || return $?

  # create user symlinks
  Call "$PROJECT_ROOT/_scripts/deploy/create_links.sh" -u . || return $?

  # generate common links file from collected and created dependencies
  Call "$PROJECT_ROOT/_scripts/deploy/gen_links.sh" . _scripts/deploy || return $?

  # patch executables
  Call patchelf --set-interpreter "./lib/ld-linux.so.2" --set-rpath "\$ORIGIN:\$ORIGIN/lib" "./$PROJECT_NAME" || return $?
  Call patchelf --shrink-rpath "./$PROJECT_NAME" || return $?

  local file

  IFS=$' \t\r\n'; for file in "${FileDepsList[@]}"; do
    MoveFile -L "$file" "lib/" || return $?
  done

  # copy approot
  Call cp -R "$PROJECT_ROOT/deploy/approot/." "$cwd" || return $?

  # copy scripts
  Call cp -R "$PROJECT_ROOT/_scripts/deploy" "$cwd/_scripts" || return $?
  Call cp -R "$PROJECT_ROOT/_scripts/admin" "$cwd/_scripts" || return $?

  local file_name

  # rename files in the current directory beginning by the `$` character
  IFS=$' \t\r\n'; for file in `find "$cwd" -type f -name "\\\$*"`; do
    GetFileDir "$file"
    file_dir="$RETURN_VALUE"

    GetFileName "$file"

    file_name_prefix=$(echo "$RETURN_VALUE" | { IFS=$'.\r\n'; read -r prefix suffix; echo "$prefix"; })
    file_name_ext=$(echo "$RETURN_VALUE" | { IFS=$'.\r\n'; read -r prefix suffix; echo "$suffix"; })
    file_name_to_rename="${file_name_prefix//\$\{PROJECT_NAME\}/$PROJECT_NAME}.$file_name_ext"

    Call mv "$file" "$file_dir/$file_name_to_rename" || return $?
  done

  return 0
}

function Pack()
{
  export CMAKE_BUILD_TYPE
  export CMAKE_BUILD_ROOT="$CMAKE_OUTPUT_ROOT/build/$CMAKE_BUILD_TYPE"

  export PATH="$PATH%:$NSIS_INSTALL_ROOT"

  MakeDir -p "$CMAKE_BUILD_ROOT"

  Pushd "$CMAKE_BUILD_ROOT" && {
    Call cmake --build . --config "$CMAKE_BUILD_TYPE" --target "$CMAKE_BUILD_TARGET" || { Popd; return $LastError; }
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

  if [[ "${Flags//-/}" != "" && "${Flags#-}" != "$Flags" ]]; then
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
  local AlwaysQuoting=1

  [[ "${EscapeFlags//a/}" != "$EscapeFlags" ]] && AlwaysQuoting=0

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
