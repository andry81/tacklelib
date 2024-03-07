#!/bin/bash

# USAGE:
#   check_config_expiration.sh [<flags>] [--] <InputFile> <OutputFile>

# Description:
#   Script to check <OutputFile> expiration versus <InputFile> to prevent
#   <OutputFile> accidental overwrite.

# <flags>:
#   --optional_compare
#     Does not require <OutputFile> existence.

# --:
#   Separator to stop parse flags.
#

# <InputFile>:
#   Input configuration file path.

# <OutputFile>:
#   Output configuration file path.
#   Must exist if `--optional_compare` is not defined.

# Script both for execution and inclusion.
[[ -n "$BASH" ]] || return 0 || exit 0 # exit to avoid continue if the return can not be called

# check inclusion guard if script is included
[[ -z "$BASH_LINENO" || BASH_LINENO[0] -eq 0 || -z "$SOURCE_TACKLELIB_TOOLS_CHECK_CONFIG_EXPIRATION_SH" || SOURCE_TACKLELIB_TOOLS_CHECK_CONFIG_EXPIRATION_SH -eq 0 ]] || return 0 || exit 0 # exit to avoid continue if the return can not be called

if [[ -z "$SOURCE_TACKLELIB_BASH_TACKLELIB_SH" || SOURCE_TACKLELIB_BASH_TACKLELIB_SH -eq 0 ]]; then
  # builtin search
  for BASH_SOURCE_DIR in "/usr/local/bin" "/usr/bin" "/bin"; do
    if [[ -f "$BASH_SOURCE_DIR/bash_tacklelib" ]]; then
      source "$BASH_SOURCE_DIR/bash_tacklelib" || exit $?
      break
    fi
  done
fi

SOURCE_TACKLELIB_TOOLS_CHECK_CONFIG_EXPIRATION_SH=1 # including guard

function tkl_check_config_expiration()
{
  local __FLAG="$1"

  local __FLAG_OPTIONAL_COMPARE=0

  local __SKIP_FLAG

  while [[ "${__FLAG:0:1}" == '-' ]]; do
    __FLAG="${__FLAG:1}"
    __SKIP_FLAG=0

    if [[ "$__FLAG" == '-optional_compare' ]]; then
      __FLAG_OPTIONAL_COMPARE=1
      __SKIP_FLAG=1
    elif [[ "$__FLAG" == '-' ]]; then
      shift
      break
    else
      echo "$0: error: invalid flag: \`-$__FLAG\`" >&2
      return 255
    fi

    #if (( ! __SKIP_FLAG )); then
    #  if [[ "${__FLAG//E/}" != "$__FLAG" ]]; then
    #    : # ...
    #  elif
    #    echo "$0: error: invalid flag: \`-${__FLAG:0:1}\`" >&2
    #    return 255
    #  fi
    #fi

    shift

    __FLAG="$1"
  done

  local VARS_FILE_IN="$1"
  local VARS_FILE="$2"

  if [[ -z "$VARS_FILE_IN" ]]; then
    echo "$BASH_SOURCE_FILE_NAME: error: input config file is not defined." >&2
    return 255
  fi

  if [[ -z "$VARS_FILE" ]]; then
    echo "$BASH_SOURCE_FILE_NAME: error: output config file is not defined." >&2
    return 255
  fi

  tkl_get_abs_path "$VARS_FILE_IN" && VARS_FILE_IN="$RETURN_VALUE"
  tkl_get_abs_path "$VARS_FILE" && VARS_FILE="$RETURN_VALUE"

  if [[ ! -e "$VARS_FILE_IN" ]]; then
    echo "$BASH_SOURCE_FILE_NAME: error: input config file does not exist: \`$VARS_FILE_IN\`." >&2
    return 255
  fi

  if [[ ! -e "$VARS_FILE" ]]; then
    if (( ! __FLAG_OPTIONAL_COMPARE )); then
      echo "$BASH_SOURCE_FILE_NAME: error: output config file does not exist: \`$VARS_FILE\`." >&2
      return 255
    else
      return 0
    fi
  fi

  if [[ "$VARS_FILE_IN" -nt "$VARS_FILE" ]]; then
    echo "$BASH_SOURCE_FILE_NAME: error: output config is expired, either merge it with or regenerate it from the input config file:"
    echo "$BASH_SOURCE_FILE_NAME: info: input config file : \`$VARS_FILE_IN\`"
    echo "$BASH_SOURCE_FILE_NAME: info: output config file: \`$VARS_FILE\`"
    return 100
  fi

  # compare versions

  local IFS
  local line
  local config_in_file_version_line config_out_file_version_line

  while IFS=$'\r\n' read -r line; do # IFS - with trim trailing line feeds
    if [[ "$line" =~ ^#%%[[:space:]]+version:[[:space:]]+([^\r\n]+) ]]; then
      tkl_rtrim_chars "${BASH_REMATCH[1]}" "[:space:]"
      config_in_file_version_line="$RETURN_VALUE"
      break
    fi
  done < "$VARS_FILE_IN"

  while IFS=$'\r\n' read -r line; do # IFS - with trim trailing line feeds
    if [[ "$line" =~ ^#%%[[:space:]]+version:[[:space:]]+([^\r\n]+) ]]; then
      tkl_rtrim_chars "${BASH_REMATCH[1]}" "[:space:]"
      config_out_file_version_line="$RETURN_VALUE"
      break
    fi
  done < "$VARS_FILE"

  if [[ -n "$config_in_file_version_line$config_out_file_version_line" && "$config_in_file_version_line" != "$config_out_file_version_line" ]]; then
    echo "$BASH_SOURCE_FILE_NAME: error: input config version line is not found in the output config file, either merge it with or regenerate it from the input config file:"
    echo "$BASH_SOURCE_FILE_NAME: info: input config file : \`$VARS_FILE_IN\`"
    echo "$BASH_SOURCE_FILE_NAME: info: output config file: \`$VARS_FILE\`"
    echo "$BASH_SOURCE_FILE_NAME: info: input config version line : \`$config_in_file_version_line\`"
    echo "$BASH_SOURCE_FILE_NAME: info: output config version line: \`$config_out_file_version_line\`"
    return 101
  fi

  return 0
}

if [[ -z "$BASH_LINENO" || BASH_LINENO[0] -eq 0 ]]; then
  # Script was not included, then execute it.
  tkl_check_config_expiration "$@"
fi
