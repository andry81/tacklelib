#!/bin/bash

# Script both for execution and inclusion.
if [[ -n "$BASH" ]]; then

if [[ -z "$SOURCE_TACKLELIB_BASH_TACKLELIB_SH" || SOURCE_TACKLELIB_BASH_TACKLELIB_SH -eq 0 ]]; then
  # builtin search
  for BASH_SOURCE_DIR in "/usr/local/bin" "/usr/bin" "/bin"; do
    [[ -f "$BASH_SOURCE_DIR/bash_tacklelib" ]] && {
      source "$BASH_SOURCE_DIR/bash_tacklelib" || exit $?
      break
    }
  done
fi

# function needs to make all support variables a local including the IFS varaible
function tkl_load_config()
{
  # CAUTION:
  #   Variables here must be unique to avoid an intersection with the loading variables!
  #

  local __CONFIG_IN_DIR="$1"
  local __CONFIG_OUT_DIR="$2"
  local __CONFIG_FILE="$3"

  if [[ -z "$__CONFIG_IN_DIR" ]]; then
    echo "$0: error: input config directory is not defined." >&2
    return 1
  fi

  if [[ -z "$__CONFIG_OUT_DIR" ]]; then
    echo "$0: error: output config directory is not defined." >&2
    return 2
  fi

  __CONFIG_IN_DIR="${__CONFIG_IN_DIR//\\//}"
  __CONFIG_OUT_DIR="${__CONFIG_OUT_DIR//\\//}"

  # CAUTION:
  #   Space before the negative value is required!
  #
  [[ "${__CONFIG_IN_DIR: -1}" == '/' ]] && __CONFIG_IN_DIR="${__CONFIG_IN_DIR::-1}"
  [[ "${__CONFIG_OUT_DIR: -1}" == '/' ]] && __CONFIG_OUT_DIR="${__CONFIG_OUT_DIR::-1}"

  if [[ ! -e "$__CONFIG_IN_DIR" ]]; then
    echo "$0: error: input config directory does not exist: \`$__CONFIG_IN_DIR\`" >&2
    return 10
  fi

  if [[ ! -e "$__CONFIG_OUT_DIR" ]]; then
    echo "$0: error: output config directory does not exist: \`$__CONFIG_OUT_DIR\`" >&2
    return 11
  fi

  if [[ ! -e "$__CONFIG_OUT_DIR/$__CONFIG_FILE" && -e "$__CONFIG_IN_DIR/$__CONFIG_FILE.in" ]]; then
    echo "\`$__CONFIG_IN_DIR/$__CONFIG_FILE.in\` -> \`$__CONFIG_OUT_DIR/$__CONFIG_FILE\`"
    cat "$__CONFIG_IN_DIR/$__CONFIG_FILE.in" > "$__CONFIG_OUT_DIR/$__CONFIG_FILE"
  fi

  # load configuration files
  if [[ ! -e "$__CONFIG_OUT_DIR/$__CONFIG_FILE" ]]; then
    echo "$0: error: config file is not found: \`$__CONFIG_OUT_DIR/$__CONFIG_FILE\`." >&2
    return 20
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
  local __ATTR
  local __VAR
  local __PLATFORM
  local __VALUE
  while IFS='=' read -r __VAR __VALUE; do
    # trim trailing line feeds
    __VAR="${__VAR%$'\r'}"
    __VALUE="${__VALUE%$'\r'}"

    [[ -z "$__VAR" ]] && continue
    [[ "$__VAR" =~ ^[[:space:]]*# ]] && continue # ignore prefix (not postfix) comments

    IFS=':' read -r __VAR __PLATFORM <<< "$__VAR"
    [[ -n "$__PLATFORM" && "$__PLATFORM" != "SH" && "$__PLATFORM" != "UNIX" && "$__PLATFORM" != "$__OSTYPE" ]] && continue

    IFS=$' \t' read -r __ATTR __VAR <<< "$__VAR"
    if [[ -z "$__VAR" ]]; then
      __VAR="$__ATTR"
      __ATTR=''
    fi

    if [[ -z "$__VALUE" ]]; then
      if [[ "$__ATTR" != 'export' ]]; then
        tkl_declare_global "$__VAR" ""
      else
        tkl_export "$__VAR" ""
      fi
      continue
    fi

    if [[ ${#__VALUE} -gt 1 && '"' == "${__VALUE:0:1}" && '"' == "${__VALUE: -1}" ]]; then
      if [[ "$__ATTR" != 'export' ]]; then
        tkl_declare_global "$__VAR" "${__VALUE:1:${#__VALUE}-2}"
      else
        tkl_export "$__VAR" "${__VALUE:1:${#__VALUE}-2}"
      fi
    else
      if [[ "$__ATTR" != 'export' ]]; then
        tkl_declare_global "$__VAR" "$__VALUE"
      else
        tkl_export "$__VAR" "$__VALUE"
      fi
    fi
  done < "$__CONFIG_OUT_DIR/$__CONFIG_FILE"

  return $?
}

function tkl_load_config_dir()
{
  local __CONFIG_IN_DIR="$1"
  local __CONFIG_OUT_DIR="$2"

  tkl_load_config "$__CONFIG_IN_DIR" "$__CONFIG_OUT_DIR" "config.system.vars" || \
  {
    echo "$BASH_SOURCE_FILE_NAME: error: \`$__CONFIG_OUT_DIR/config.system.vars\` is not loaded."
    tkl_abort 255
  } >&2

  for (( i=0; ; i++ )); do
    [[ ! -e "$__CONFIG_IN_DIR/config.$i.vars.in" ]] && break

    tkl_load_config "$__CONFIG_IN_DIR" "$__CONFIG_OUT_DIR" "config.$i.vars" || \
    {
      echo "$BASH_SOURCE_FILE_NAME: error: \`$__CONFIG_OUT_DIR/config.$i.vars\` is not loaded."
      tkl_abort 255
    } >&2
  done
}

if [[ -z "$BASH_LINENO" || BASH_LINENO[0] -eq 0 ]]; then
  # Script was not included, then execute it.
  tkl_load_config "$@"
fi

fi
