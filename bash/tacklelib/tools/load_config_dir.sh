#!/bin/bash

# USAGE:
#   load_config_dir.sh [<flags>] [--] <InputDir> <OutputDir> [<Param0> [<Param1>]]

# Description:
#   Script to load input and output directory with configuration files using
#   the `load_Config.sh` script.
#
#   A directory can contain a set of configuration files which loads in this
#   order if exist:
#     * config.system.vars[.in]
#     * config.0.vars[.in]
#     * ...
#     * config.N.vars[.in]
#
#   The `.in` suffix basically related to the configuration files in the
#   input directory.
#
#   By default the script does load the system and the user configuration
#   files from the input directory.
#
#   NOTE:
#     All the rest description is in the `load_config.sh` script.

# <flags>:
#   --gen-system-config
#     Generates the system configuration file.
#     Implies `--load-system-output-config` flag.
#
#   --gen-user-config
#     Generates the user configuration file.
#     Implies `--load-user-output-config` flag.
#
#   --load-system-output-config
#     Loads the system configuration file from output directory.
#
#   --load-user-output-config
#     Loads the user configuration file(s) from output directory.
#
#   --no-load-system-config
#     Skips load the system configuration file.
#
#   --no-load-user-config
#     Skips load the user configuration file(s).
#
#   --expand-system-config-bat-vars
#     Allow %-variables expansion in the system config.
#
#   --expand-system-config-tkl-vars
#     Allow $/-variables expansion in the system config.
#
#   --expand-user-config-bat-vars
#     Allow %-variables expansion in the user config.
#
#   --expand-user-config-tkl-vars
#     Allow $/-variables expansion in the user config.
#
#   --expand-all-configs-bat-vars
#     Allow %-variables expansion in all configs.
#
#   --expand-all-configs-tkl-vars
#     Allow $/-variables expansion in all configs.

# --:
#   Separator to stop parse flags.
#

# <InputDir>:
#   Input configuration file directory.
#   Must be not empty and exist.

# <OutputDir>:
#   Output configuration file directory.
#   Can be empty, then `<InputDir>` is used instead.

# NOTE:
#   All the rest parameters is in the `load_config.sh` script.

# Script both for execution and inclusion.
[[ -n "$BASH" ]] || return 0 || exit 0 # exit to avoid continue if the return can not be called

# check inclusion guard if script is included
[[ -z "$BASH_LINENO" || BASH_LINENO[0] -eq 0 || -z "$SOURCE_TACKLELIB_TOOLS_LOAD_CONFIG_DIR_SH" || SOURCE_TACKLELIB_TOOLS_LOAD_CONFIG_DIR_SH -eq 0 ]] || return 0 || exit 0 # exit to avoid continue if the return can not be called

if [[ -z "$SOURCE_TACKLELIB_BASH_TACKLELIB_SH" || SOURCE_TACKLELIB_BASH_TACKLELIB_SH -eq 0 ]]; then
  # builtin search
  for BASH_SOURCE_DIR in '/usr/local/bin' '/usr/bin' '/bin'; do
    if [[ -f "$BASH_SOURCE_DIR/bash_tacklelib" ]]; then
      source "$BASH_SOURCE_DIR/bash_tacklelib" || exit $?
      break
    fi
  done
fi

SOURCE_TACKLELIB_TOOLS_LOAD_CONFIG_DIR_SH=1 # including guard

tkl_include_or_abort 'load_config.sh'

if [[ -n "${TACKLELIB_BASH_ROOT+x}" ]]; then
  tkl_include_or_abort "$TACKLELIB_BASH_ROOT/tacklelib/buildlib.sh"
else
  tkl_include_or_abort "../buildlib.sh"
fi

function tkl_load_config_dir()
{
  # CAUTION:
  #   Variables here must be unique to avoid an intersection with the loading variables!
  #

  local __FLAG="$1"

  local __FLAG_GEN_SYSTEM_CONFIG=0
  local __FLAG_GEN_USER_CONFIG=0
  local __FLAG_LOAD_SYSTEM_OUTPUT_CONFIG=0
  local __FLAG_LOAD_USER_OUTPUT_CONFIG=0
  local __FLAG_NO_LOAD_SYSTEM_CONFIG=0
  local __FLAG_NO_LOAD_USER_CONFIG=0
  local __FLAG_EXPAND_SYSTEM_CONFIG_BAT_VARS=0
  local __FLAG_EXPAND_SYSTEM_CONFIG_TKL_VARS=0
  local __FLAG_EXPAND_USER_CONFIG_BAT_VARS=0
  local __FLAG_EXPAND_USER_CONFIG_TKL_VARS=0
  local __FLAG_EXPAND_ALL_CONFIGS_BAT_VARS=0
  local __FLAG_EXPAND_ALL_CONFIGS_TKL_VARS=0
  local __BARE_SYSTEM_FLAGS
  local __BARE_USER_FLAGS

  local __SKIP_FLAG

  while [[ "${__FLAG:0:1}" == '-' ]]; do
    __FLAG="${__FLAG:1}"
    __SKIP_FLAG=0

    if [[ "$__FLAG" == '-gen-system-config' ]]; then
      __FLAG_GEN_SYSTEM_CONFIG=1
      __BARE_SYSTEM_FLAGS="$__BARE_SYSTEM_FLAGS --gen-config"
      __SKIP_FLAG=1
    elif [[ "$__FLAG" == '-gen-user-config' ]]; then
      __FLAG_GEN_USER_CONFIG=1
      __BARE_USER_FLAGS="$__BARE_USER_FLAGS --gen-config"
      __SKIP_FLAG=1
    elif [[ "$__FLAG" == '-load-system-output-config' ]]; then
      __FLAG_LOAD_SYSTEM_OUTPUT_CONFIG=1
      __BARE_SYSTEM_FLAGS="$__BARE_SYSTEM_FLAGS --load-output-config"
      __SKIP_FLAG=1
    elif [[ "$__FLAG" == '-load-user-output-config' ]]; then
      __FLAG_LOAD_USER_OUTPUT_CONFIG=1
      __BARE_USER_FLAGS="$__BARE_USER_FLAGS --load-output-config"
      __SKIP_FLAG=1
    elif [[ "$__FLAG" == '-no-load-system-config' ]]; then
      __FLAG_NO_LOAD_SYSTEM_CONFIG=1
      __SKIP_FLAG=1
    elif [[ "$__FLAG" == '-no-load-user-config' ]]; then
      __FLAG_NO_LOAD_USER_CONFIG=1
      __SKIP_FLAG=1
    elif [[ "$__FLAG" == '-expand-system-config-bat-vars' ]]; then
      __FLAG_EXPAND_SYSTEM_CONFIG_BAT_VARS=1
      __BARE_SYSTEM_FLAGS="$__BARE_SYSTEM_FLAGS --expand-bat-vars"
      __SKIP_FLAG=1
    elif [[ "$__FLAG" == '-expand-system-config-tkl-vars' ]]; then
      __FLAG_EXPAND_SYSTEM_CONFIG_TKL_VARS=1
      __BARE_SYSTEM_FLAGS="$__BARE_SYSTEM_FLAGS --expand-tkl-vars"
      __SKIP_FLAG=1
    elif [[ "$__FLAG" == '-expand-user-config-bat-vars' ]]; then
      __FLAG_EXPAND_USER_CONFIG_BAT_VARS=1
      __BARE_USER_FLAGS="$__BARE_USER_FLAGS --expand-bat-vars"
      __SKIP_FLAG=1
    elif [[ "$__FLAG" == '-expand-user-config-tkl-vars' ]]; then
      __FLAG_EXPAND_USER_CONFIG_TKL_VARS=1
      __BARE_USER_FLAGS="$__BARE_USER_FLAGS --expand-tkl-vars"
      __SKIP_FLAG=1
    elif [[ "$__FLAG" == '-expand-all-configs-bat-vars' ]]; then
      __FLAG_EXPAND_ALL_CONFIGS_BAT_VARS=1
      __BARE_SYSTEM_FLAGS="$__BARE_SYSTEM_FLAGS --expand-bat-vars"
      __BARE_USER_FLAGS="$__BARE_USER_FLAGS --expand-bat-vars"
      __SKIP_FLAG=1
    elif [[ "$__FLAG" == '-expand-all-configs-tkl-vars' ]]; then
      __FLAG_EXPAND_ALL_CONFIGS_TKL_VARS=1
      __BARE_SYSTEM_FLAGS="$__BARE_SYSTEM_FLAGS --expand-tkl-vars"
      __BARE_USER_FLAGS="$__BARE_USER_FLAGS --expand-tkl-vars"
      __SKIP_FLAG=1
    elif [[ "$__FLAG" == '-' ]]; then
      shift
      break
    fi

    if (( ! __SKIP_FLAG )); then
      __BARE_SYSTEM_FLAGS="$__BARE_SYSTEM_FLAGS -$__FLAG"
      __BARE_USER_FLAGS="$__BARE_USER_FLAGS -$__FLAG"
      #if [[ "${__FLAG//E/}" != "$__FLAG" ]]; then
      #  : # ...
      #else
      #  echo "$BASH_SOURCE_FILE_NAME: error: invalid flag: \`-${__FLAG:0:1}\`" >&2
      #  return 255
      #fi
    fi

    shift

    __FLAG="$1"
  done

  local __CONFIG_DIR_IN="$1"
  local __CONFIG_DIR_OUT="$2"

  if (( NO_GEN )); then
    if (( __FLAG_GEN_SYSTEM_CONFIG )); then
      echo "$BASH_SOURCE_FILE_NAME: error: can not generate system config while NO_GEN is set." >&2
      return 255
    fi
    if (( __FLAG_GEN_USER_CONFIG )); then
      echo "$BASH_SOURCE_FILE_NAME: error: can not generate user config while NO_GEN is set." >&2
      return 255
    fi
  fi

  local __SYSTEM_CONFIG_FILE_NAME_DIR="$__CONFIG_DIR_OUT"
  local __USER_CONFIG_FILE_NAME_DIR="$__CONFIG_DIR_OUT"
  local __SYSTEM_CONFIG_FILE_EXT
  local __USER_CONFIG_FILE_EXT

  if (( ! __FLAG_LOAD_SYSTEM_OUTPUT_CONFIG && ! __FLAG_GEN_SYSTEM_CONFIG )); then
    __SYSTEM_CONFIG_FILE_NAME_DIR="$__CONFIG_DIR_IN"
    __SYSTEM_CONFIG_FILE_EXT='.in'
  fi
  if (( ! __FLAG_LOAD_USER_OUTPUT_CONFIG && ! __FLAG_GEN_USER_CONFIG )); then
    __USER_CONFIG_FILE_NAME_DIR="$__CONFIG_DIR_IN"
    __USER_CONFIG_FILE_EXT='.in'
  fi

  if [[ -z "$__CONFIG_DIR_OUT" ]]; then
    __CONFIG_DIR_OUT="$__CONFIG_DIR_IN"
  fi

  if (( ! __FLAG_NO_LOAD_SYSTEM_CONFIG )); then
    eval tkl_call_and_print_if '"(( LOAD_CONFIG_VERBOSE ))"' \
      tkl_load_config$__BARE_SYSTEM_FLAGS -- '"$__CONFIG_DIR_IN"' '"$__CONFIG_DIR_OUT"' '"config.system.vars$__SYSTEM_CONFIG_FILE_EXT"' '"${@:3}"' || \
    {
      echo "$BASH_SOURCE_FILE_NAME: error: \`$__SYSTEM_CONFIG_FILE_NAME_DIR/config.system.vars$__SYSTEM_CONFIG_FILE_EXT\` is not loaded."
      return 255
    } >&2
  fi

  if (( ! __FLAG_NO_LOAD_USER_CONFIG )); then
    # CAUTION:
    #   In case of output config generation we must stop loading only when both input and output user config does not exist to avoid misload on misgeneration.
    #
    for (( i=0; ; i++ )); do
      if [[ ! -e "$__USER_CONFIG_FILE_NAME_DIR/config.$i.vars$__USER_CONFIG_FILE_EXT" ]]; then
        break
      fi

      if [[ "$__USER_CONFIG_FILE_EXT" != '.in' && ! -e "$__CONFIG_DIR_IN/config.$i.vars.in" ]]; then
        break
      fi

      eval tkl_call_and_print_if '"(( LOAD_CONFIG_VERBOSE ))"' \
        tkl_load_config$__BARE_USER_FLAGS -- '"$__CONFIG_DIR_IN"' '"$__CONFIG_DIR_OUT"' '"config.$i.vars$__USER_CONFIG_FILE_EXT"' '"${@:3}"' || \
      {
        echo "$BASH_SOURCE_FILE_NAME: error: \`$__CONFIG_DIR_OUT/config.$i.vars$__USER_CONFIG_FILE_EXT\` is not loaded."
        return 255
      } >&2
    done
  fi
}

if [[ -z "$BASH_LINENO" || BASH_LINENO[0] -eq 0 ]]; then
  # Script was not included, then execute it.
  tkl_load_config_dir "$@"
fi
