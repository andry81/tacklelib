#!/bin/bash

# USAGE:
#   load_config.sh [<flags>] [--] <InputDir> <OutputDir> <ConfigFileName> [<Param0> [<Param1>]]

# Description:
#   Script to load a configuration file which can consist of an input and
#   output parts.
#
#   The input configuration file is determinded by the `.in` suffix in the
#   file name and basically stores in a version control system.
#   The output configuration file must not contain the `.in` suffix in the
#   file name and is used as a local storage for a user values.
#
#   The script detects the input file change time versus the output file change
#   time and if the former is later, then interrupts the load with an
#   error.
#
#   Additionally the `#%% version: ...` line is used to force the user to
#   manually update the output configuration file from the input
#   configuration file in case if are not equal.
#
#   By default the script does load the input configuration from the
#   `<ConfigFileName>` file.
#
#   If `--gen-config` or `--load-output-config` flag is used, then the
#   input configuration file name is used as `<ConfigFileName>.in`.

# <flags>:
#   --gen-config
#     Generates the output configuration file from the input configuration
#     file if the output configuration file does not exist, otherwise skips
#     the generation.
#     Implies `--load-output-config` flag.
#
#   --load-output-config
#     Loads the output configuration file instead of the input configuration
#     file as by default.
#
#   --expand-bat-vars
#     Allow %-variables expansion.
#     The only `%<variable>%` placeholders can be expanded into a variable
#     value.
#     If `--ignore-unexist` flag is not defined and if a variable does not
#     exist, then does replace the placeholder into `*:%<variable>%` sequence.
#     Use the double `%` character to escape `%` character.
#
#   --expand-tkl-vars:
#     Allow $/-variables expansion.
#     The only `$/{<variable>}` placeholders can be expanded into a variable
#     value.
#     If `--ignore-unexist` flag is not defined and if a variable name is empty
#     or a variable does not exist, then does replace the placeholder into
#     `*:$/{<variable>}` sequence.
#     Use the `$/<char>` sequence to escape `<char>` character.
#
#   --export-vars
#     Export all variables.
#
#   --ignore-unexist
#     Ignores unexisted variables.
#     Does not substitute an unexisted variable placeholder with `*:` prefix.

# --:
#   Separator to stop parse flags.
#

# <InputDir>:
#   Input configuration file directory.
#   Must be not empty and exist.

# <OutputDir>:
#   Output configuration file directory.
#   Must be not empty.
#   May not exist if the script does load the input configuration file.

# <ConfigFileName>:
#   Input/Output configuration file.
#   May contain `.in` suffix if the script does load the input configuration
#   file only. In all other cases - must not.

# <Param0>, <Param1>:
#   Parameterizes the loader to load additionally custom variables.
#   If not defined, then custom variables does ignore.

# CONFIGURATION FILE FORMAT:
#   [<attributes>] <variable>[:<class_name>]=<value>
#   [<attributes>] <variable>[:[<param0>][:[<param1>]]]=<value>
#
# <attributes>:           Variable space separated attributes: once | export | upath
# <variable>:             Variable name corresponding to the regex: [_a-zA-Z][_a-zA-Z0-9]*
# <class_name>:           Builtin class variant names: OSWIN | OSUNIX | BAT | SH
#   OSWIN:                Apply on Windows system including cygwin/mingw/msys subsystems.
#   OSUNIX:               Apply on Unix/Linux systems excluding cygwin/mingw/msys subsystems.
#   BAT:                  Apply on Windows system when this file has loaded from the Windows batch script loader.
#   SH:                   Apply on any system when this file has loaded from the Bash shell script loader.
#
# <param0>, <param1>:     Custom variable parameters.
#                         Example:
#                           <Param0>=OSWINXP
#                           <Param1>=OS32
#
#                           Loads besides the builtin variable classes, these:
#                           A:OSWINXP=...
#                           B:OSWINXP:OS32=...
#                           C::OS32=...
#
# <value>:                Value with substitution support:
#                         * --expand-bat-vars:  `%<variable>%`.
#                         * --expand-tkl-vars:  `$/{<variable>}`.
#                         Can start by the `"` quote character, but two quotes does remove only when exist on both ends of a value.

# <attributes>:
#   once
#     Sets the variable only if it is not defined.
#   export
#     (Unix shell only)
#     Exports the variable additionally to the set.
#   upath
#     Treats a variable value as a path and converts it to a uniform path
#     (use forward slashes only).

# Parse logic:
#   Uses %-variables or/and $/-variables expansion.
#   %-variables does expand at first.

# Script both for execution and inclusion.
[[ -n "$BASH" ]] || return 0 || exit 0 # exit to avoid continue if the return can not be called

# check inclusion guard if script is included
[[ -z "$BASH_LINENO" || BASH_LINENO[0] -eq 0 || -z "$SOURCE_TACKLELIB_TOOLS_LOAD_CONFIG_SH" || SOURCE_TACKLELIB_TOOLS_LOAD_CONFIG_SH -eq 0 ]] || return 0 || exit 0 # exit to avoid continue if the return can not be called

if [[ -z "$SOURCE_TACKLELIB_BASH_TACKLELIB_SH" || SOURCE_TACKLELIB_BASH_TACKLELIB_SH -eq 0 ]]; then
  # builtin search
  for BASH_SOURCE_DIR in '/usr/local/bin' '/usr/bin' '/bin'; do
    if [[ -f "$BASH_SOURCE_DIR/bash_tacklelib" ]]; then
      source "$BASH_SOURCE_DIR/bash_tacklelib" || exit $?
      break
    fi
  done
fi

SOURCE_TACKLELIB_TOOLS_LOAD_CONFIG_SH=1 # including guard

tkl_include_or_abort 'load_config_dir.sh'
tkl_include_or_abort 'check_config_expiration.sh'

if [[ -n "${TACKLELIB_BASH_ROOT+x}" ]]; then
  tkl_include_or_abort "$TACKLELIB_BASH_ROOT/tacklelib/buildlib.sh"
else
  tkl_include_or_abort "../buildlib.sh"
fi

# Function needs to make all support variables a local including the IFS variable.
function tkl_load_config()
{
  # CAUTION:
  #   Variables here must be unique to avoid an intersection with the loading variables!
  #

  local __FLAG="$1"

  local __FLAG_GEN_CONFIG=0
  local __FLAG_LOAD_OUTPUT_CONFIG=0
  local __FLAG_EXPAND_BAT_VARS=0
  local __FLAG_EXPAND_TKL_VARS=0
  local __FLAG_EXPORT_VARS=0
  local __FLAG_IGNORE_UNEXIST=0

  local __SKIP_FLAG

  while [[ "${__FLAG:0:1}" == '-' ]]; do
    __FLAG="${__FLAG:1}"
    __SKIP_FLAG=0

    if [[ "$__FLAG" == '-gen-config' ]]; then
      __FLAG_GEN_CONFIG=1
      __SKIP_FLAG=1
    elif [[ "$__FLAG" == '-load-output-config' ]]; then
      __FLAG_LOAD_OUTPUT_CONFIG=1
      __SKIP_FLAG=1
    elif [[ "$__FLAG" == '-expand-bat-vars' ]]; then
      __FLAG_EXPAND_BAT_VARS=1
      __SKIP_FLAG=1
    elif [[ "$__FLAG" == '-expand-tkl-vars' ]]; then
      __FLAG_EXPAND_TKL_VARS=1
      __SKIP_FLAG=1
    elif [[ "$__FLAG" == '-export-vars' ]]; then
      __FLAG_EXPORT_VARS=1
      __SKIP_FLAG=1
    elif [[ "$__FLAG" == '-ignore-unexist' ]]; then
      __FLAG_IGNORE_UNEXIST=1
      __SKIP_FLAG=1
    elif [[ "$__FLAG" == '-' ]]; then
      shift
      break
    else
      echo "$BASH_SOURCE_FILE_NAME: error: invalid flag: \`-$__FLAG\`" >&2
      return 255
    fi

    #if (( ! __SKIP_FLAG )); then
    #  if [[ "${__FLAG//E/}" != "$__FLAG" ]]; then
    #    : # ...
    #  elif
    #    echo "$BASH_SOURCE_FILE_NAME: error: invalid flag: \`-${__FLAG:0:1}\`" >&2
    #    return 255
    #  fi
    #fi

    shift

    __FLAG="$1"
  done

  local __CONFIG_DIR_IN="$1"
  local __CONFIG_DIR_OUT="$2"
  local __CONFIG_FILE_NAME="$3"
  local __PARAM0="$4"
  local __PARAM1="$5"

  if [[ -z "$__CONFIG_DIR_IN" ]]; then
    echo "$BASH_SOURCE_FILE_NAME: error: input config directory is not defined." >&2
    return 1
  fi

  if [[ -z "$__CONFIG_DIR_OUT" ]]; then
    echo "$BASH_SOURCE_FILE_NAME: error: output config directory is not defined." >&2
    return 2
  fi

  __CONFIG_DIR_IN="${__CONFIG_DIR_IN//\\//}"
  __CONFIG_DIR_OUT="${__CONFIG_DIR_OUT//\\//}"

  # CAUTION:
  #   Space before the negative value is required!
  #
  [[ "${__CONFIG_DIR_IN: -1}" == '/' ]] && __CONFIG_DIR_IN="${__CONFIG_DIR_IN::-1}"
  [[ "${__CONFIG_DIR_OUT: -1}" == '/' ]] && __CONFIG_DIR_OUT="${__CONFIG_DIR_OUT::-1}"

  if [[ ! -e "$__CONFIG_DIR_IN" ]]; then
    echo "$BASH_SOURCE_FILE_NAME: error: input config directory does not exist: \`$__CONFIG_DIR_IN\`" >&2
    return 10
  fi

  if (( __FLAG_GEN_CONFIG || __FLAG_LOAD_OUTPUT_CONFIG )) && [[ ! -e "$__CONFIG_DIR_OUT" ]]; then
    echo "$BASH_SOURCE_FILE_NAME: error: output config directory does not exist: \`$__CONFIG_DIR_OUT\`" >&2
    return 11
  fi

  local __CONFIG_FILE_NAME_GENERATED=0
  local __CONFIG_FILE_NAME_DIR="$__CONFIG_DIR_OUT"

  if (( ! __FLAG_GEN_CONFIG )); then
    if (( ! __FLAG_LOAD_OUTPUT_CONFIG )); then
      __CONFIG_FILE_NAME_DIR="$__CONFIG_DIR_IN"
    fi
  else
    if [[ ! -e "$__CONFIG_DIR_OUT/$__CONFIG_FILE_NAME" && -e "$__CONFIG_DIR_IN/$__CONFIG_FILE_NAME.in" ]]; then
      echo "\`$__CONFIG_DIR_IN/$__CONFIG_FILE_NAME.in\` -> \`$__CONFIG_DIR_OUT/$__CONFIG_FILE_NAME\`"
      cat "$__CONFIG_DIR_IN/$__CONFIG_FILE_NAME.in" > "$__CONFIG_DIR_OUT/$__CONFIG_FILE_NAME"
      __CONFIG_FILE_NAME_GENERATED=1
    fi
  fi

  # load configuration files
  if [[ ! -e "$__CONFIG_FILE_NAME_DIR/$__CONFIG_FILE_NAME" ]]; then
    echo "$BASH_SOURCE_FILE_NAME: error: config file is not found: \`$__CONFIG_FILE_NAME_DIR/$__CONFIG_FILE_NAME\`." >&2
    return 20
  fi

  if (( __FLAG_GEN_CONFIG || __FLAG_LOAD_OUTPUT_CONFIG )) && \
     (( ! __CONFIG_FILE_NAME_GENERATED )) && \
     [[ -e "$__CONFIG_DIR_IN/$__CONFIG_FILE_NAME.in" ]]; then
     tkl_check_config_expiration -- "$__CONFIG_DIR_IN/$__CONFIG_FILE_NAME.in" "$__CONFIG_FILE_NAME_DIR/$__CONFIG_FILE_NAME" || return $?
  fi

  local __OSTYPE
  case "$OSTYPE" in
    cygwin* | msys* | mingw*)
      __OSTYPE=OSWIN
    ;;
    *)
      __OSTYPE=OSUNIX
    ;;
  esac

  local IFS # split by character
  local __ATTR __ARG __VAR __VALUE __P0 __P1
  local __BUF __INDEX __LAST_INDEX __VALUE_LEN __VALUE_EXPANDED __IS_IN_PLACEHOLDER
  local RETURN_VALUE

  while IFS=$'=\r\n' read -r __VAR __VALUE; do # IFS - with trim trailing line feeds
    [[ -n "$__VAR" ]] || continue
    [[ ! "$__VAR" =~ ^[[:space:]]*# ]] || continue # ignore prefix (not postfix) comments

    IFS=$' \t' read -r __ARG __VAR <<< "$__VAR"
    if [[ -n "$__VAR" ]]; then
      __ATTR=("$__ARG")
      while [[ "$__VAR" =~ [[:space:]] ]]; do
        IFS=$' \t' read -r __ARG __VAR <<< "$__VAR"
        __ATTR[${#__ATTR}]="$__ARG"
      done
    else
      __VAR="$__ARG"
      [[ -n "$__VAR" ]] || continue
      __ATTR=()
    fi

    IFS=':' read -r __VAR __P0 __P1 <<< "$__VAR"

    tkl_trim_chars "$__VAR" '[:space:]'
    __VAR="$RETURN_VALUE"

    [[ -n "$__VAR" ]] || continue

    # preprocess without expansion
    tkl_trim_chars "$__VALUE" '[:space:]'
    __VALUE="$RETURN_VALUE"

    __VALUE_LEN=${#__VALUE}
    if [[ __VALUE_LEN -gt 1 && '"' == "${__VALUE:0:1}" && '"' == "${__VALUE: -1}" ]]; then
      __VALUE="${__VALUE:1:__VALUE_LEN-2}"
    fi

    # %-variables does expand at first
    if (( __FLAG_EXPAND_BAT_VARS )); then
      __VALUE_LEN=${#__VALUE}
      __VALUE_EXPANDED=''
      __IS_IN_PLACEHOLDER=0
      for (( __INDEX=0, __LAST_INDEX=0; __INDEX < __VALUE_LEN; __INDEX++ )); do
        if [[ "${__VALUE:__INDEX:1}" == '%' ]]; then
          __BUF="${__VALUE:__LAST_INDEX:__INDEX-__LAST_INDEX}"
          if (( __IS_IN_PLACEHOLDER )); then
            __IS_IN_PLACEHOLDER=0
            if [[ -n "$__BUF" ]]; then
              # WORKAROUND: regexp on variable name to avoid below if condition silent breakage
              if [[ "$__BUF" =~ ^[_a-zA-Z][_a-zA-Z0-9]*$ ]] && [[ "${!__BUF+x}" ]] 2>/dev/null; then
                __VALUE_EXPANDED="$__VALUE_EXPANDED${!__BUF}"
              elif (( ! __FLAG_IGNORE_UNEXIST )); then
                __VALUE_EXPANDED="$__VALUE_EXPANDED*:%$__BUF%" # unexisted variable sequence placeholder
              else
                __VALUE_EXPANDED="$__VALUE_EXPANDED%$__BUF%"
              fi
            else
              __VALUE_EXPANDED="$__VALUE_EXPANDED%" # % escape sequence
            fi
          else
            __IS_IN_PLACEHOLDER=1
            __VALUE_EXPANDED="$__VALUE_EXPANDED$__BUF"
          fi
          (( __LAST_INDEX = __INDEX+1 ))
        fi
      done
      if (( __IS_IN_PLACEHOLDER )); then
        __VALUE_EXPANDED="$__VALUE_EXPANDED%"
      fi
      if (( __LAST_INDEX < __INDEX )); then
        __VALUE_EXPANDED="$__VALUE_EXPANDED${__VALUE:__LAST_INDEX:__INDEX-__LAST_INDEX}"
      fi
      __VALUE="$__VALUE_EXPANDED"
      __VALUE_LEN=${#__VALUE}
    fi

    # $/-variables does expand at second
    if (( __FLAG_EXPAND_TKL_VARS )); then
      __VALUE_LEN=${#__VALUE}
      __VALUE_EXPANDED=''
      __IS_IN_PLACEHOLDER=0
      for (( __INDEX=0, __LAST_INDEX=0; __INDEX < __VALUE_LEN; __INDEX++ )); do
        if (( ! __IS_IN_PLACEHOLDER )); then
          if [[ "${__VALUE:__INDEX:3}" == '$/{' ]]; then # $/{<variable>} sequence
            __IS_IN_PLACEHOLDER=1
            __BUF="${__VALUE:__LAST_INDEX:__INDEX-__LAST_INDEX}"
            __VALUE_EXPANDED="$__VALUE_EXPANDED$__BUF"
            (( __INDEX += 2 )) # start sequence skip
            (( __LAST_INDEX = __INDEX+1 ))
          elif [[ "${__VALUE:__INDEX:2}" == '$/' ]]; then # $/<char> escape sequence
            if (( __INDEX + 2 < __VALUE_LEN )); then
              __BUF="${__VALUE:__LAST_INDEX:__INDEX-__LAST_INDEX}"
              __VALUE_EXPANDED="$__VALUE_EXPANDED$__BUF${__VALUE:__INDEX+2:1}"
              (( __INDEX += 2 )) # sequence skip
              (( __LAST_INDEX = __INDEX+1 ))
            else
              (( __INDEX += 1 )) # sequence skip
            fi
          fi
        else
          if [[ "${__VALUE:__INDEX:1}" == '}' ]]; then
            __IS_IN_PLACEHOLDER=0
            __BUF="${__VALUE:__LAST_INDEX:__INDEX-__LAST_INDEX}"
            if [[ -n "$__BUF" ]]; then
              # WORKAROUND: regexp on variable name to avoid below if condition silent breakage
              if [[ "$__BUF" =~ ^[_a-zA-Z][_a-zA-Z0-9]*$ ]] && [[ "${!__BUF+x}" ]] 2>/dev/null; then
                __VALUE_EXPANDED="$__VALUE_EXPANDED${!__BUF}"
              elif (( ! __FLAG_IGNORE_UNEXIST )); then
                __VALUE_EXPANDED="$__VALUE_EXPANDED*:\$/{$__BUF}" # unexisted variable sequence placeholder
              else
                __VALUE_EXPANDED="$__VALUE_EXPANDED\$/{$__BUF}"
              fi
            elif (( ! __FLAG_IGNORE_UNEXIST )); then
              __VALUE_EXPANDED="$__VALUE_EXPANDED*:\$/{}" # empty sequence placeholder
            else
              __VALUE_EXPANDED="$__VALUE_EXPANDED\$/{}"
            fi
            (( __LAST_INDEX = __INDEX+1 ))
          fi
        fi
      done
      if (( __IS_IN_PLACEHOLDER )); then
        __VALUE_EXPANDED="$__VALUE_EXPANDED*:$/{" # incomplete sequence is empty sequence
      fi
      if (( __LAST_INDEX < __INDEX )); then
        __VALUE_EXPANDED="$__VALUE_EXPANDED${__VALUE:__LAST_INDEX:__INDEX-__LAST_INDEX}"
      fi
      __VALUE="$__VALUE_EXPANDED"
      __VALUE_LEN=${#__VALUE}
    fi

    tkl_trim_chars "$__P0" '[:space:]'
    __P0="$RETURN_VALUE"

    if [[ -n "$__P0" ]]; then
      [[ "$__P0" != 'BAT' && ( "$__P0" == 'SH' || "$__P0" == "$__OSTYPE" || -n "$__PARAM0" && "$__PARAM0" == "$__P0" ) ]] || continue # skip builtin or custom parameter if not equals
    fi

    tkl_trim_chars "$__P1" '[:space:]'
    __P1="$RETURN_VALUE"

    if [[ -n "$__P1" ]]; then
      [[ -n "$__PARAM1" && "$__PARAM1" == "$__P1" ]] || continue # skip custom parameter if not equals
    fi

    if [[ "${__ATTR[*]}" =~ ([[:space:]]|^)once([[:space:]]|$) ]]; then
      # WORKAROUND: regexp on variable name to avoid below if condition silent breakage
      [[ ! "$__VAR" =~ ^[_a-zA-Z][_a-zA-Z0-9]$ ]] || [[ ! "${!__VAR+x}" ]] 2>/dev/null || continue # skip existed variable
    fi

    #echo "$__VAR:$__P0:$__P1=$__VALUE"

    if [[ -z "$__VALUE" ]]; then
      if (( ! __FLAG_EXPORT_VARS )) && [[ ! "${__ATTR[*]}" =~ ([[:space:]]|^)export([[:space:]]|$) ]]; then
        tkl_declare_global "$__VAR" ""
      else
        tkl_export "$__VAR" ""
      fi
      continue
    fi

    if (( ! __FLAG_EXPORT_VARS )) && [[ ! "${__ATTR[*]}" =~ ([[:space:]]|^)export([[:space:]]|$) ]]; then
      tkl_declare_global "$__VAR" "$__VALUE"
    else
      tkl_export "$__VAR" "$__VALUE"
    fi
  done < "$__CONFIG_FILE_NAME_DIR/$__CONFIG_FILE_NAME"

  return $?
}

if [[ -z "$BASH_LINENO" || BASH_LINENO[0] -eq 0 ]]; then
  # Script was not included, then execute it.
  tkl_load_config "$@"
fi
