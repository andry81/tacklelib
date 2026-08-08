#!/usr/bin/env bash

# Script both for execution and inclusion.
[[ -n "$BASH" ]] || return 0 || exit 0 # exit to avoid continue if the return can not be called

# check inclusion guard if script is included
[[ -z "$BASH_LINENO" || BASH_LINENO[0] -eq 0 ]] || (( ! SOURCE_TACKLELIB_TOOLS_DETECT_SHELL_USERDIR_FILE_SH )) || return 0 || exit 0 # exit to avoid continue if the return can not be called

(( SOURCE_TACKLELIB_BASH_TACKLELIB_SH )) || source bash_tacklelib || return 255 || exit 255 # exit to avoid continue if the return can not be called

SOURCE_TACKLELIB_TOOLS_DETECT_SHELL_USERDIR_FILE_SH=1 # including guard

function path_distance_rel_to()
{
  local path0="$1"
  local path1="$2"
  local dist
  local relpath="$(realpath -m --relative-to="$path0" -- "$path1")"

  if [[ "$relpath" == ".." || "$relpath" == */.. ]]; then
    relpath="${relpath}/"
  fi

  while [[ "$relpath" == ../* ]]; do
    dist=$((dist + 1))
    relpath="${relpath#../}"
  done

  if [[ -n "$dist" ]]; then
    RETURN_VALUE=$dist
    return 0
  fi

  RETURN_VALUE=''

  return 1
}

# return nothing if different drives
function path_distance()
{
  path_distance_rel_to "$1" "$2"
  local dist0=$RETURN_VALUE

  path_distance_rel_to "$2" "$1"
  local dist1=$RETURN_VALUE

  if [[ -n "$dist0$dist1" ]]; then
    RETURN_VALUE=$(( dist0 + dist1 ))
    return 0
  fi

  RETURN_VALUE=''

  return 1
}

# Based on:
#   https://stackoverflow.com/questions/71928010/makefile-on-windows-is-there-a-way-to-force-make-to-use-the-mingw-find-exe/76393735#76393735
#
function detect_shell_userdir_file()
{
  local __var="$1"
  local __value="$2"
  local __is_found=0

  local IFS

  # NOTE:
  #   The `${path,,}` or `${path^^}` form has issues:
  #     1. Does not handle a unicode string case conversion correctly (unicode characters translation in words).
  #     2. Supported in Bash 4+.

  # detect a shell package executable behind directories from the `PATH` variable
  if [[ -n "${SHELL+x}" ]] && \
      which where >/dev/null 2>&1 && \
      which realpath >/dev/null 2>&1 && \
      which cygpath >/dev/null 2>&1; then
    __value="${__value//\\//}"

    local OLD_SHOPT
    tkl_set_shopt_nocasematch

    local __shell="$(realpath -- "$(cygpath -w -- "$SHELL")")"
    local __path
    local __paths=()
    local __dists=()

    local RETURN_VALUE

    IFS=$'\r\n'; for __path in `where "$__value" 2>/dev/null`; do # IFS - with trim trailing line feeds
      __path="$(cygpath -w -- "$(realpath -- "${__path//\\//}")")"
      __path="${__path//\\//}"

      # collect paths and distances to `SHELL` variable value
      path_distance "$__path" "$__shell"

      IFS=$' \t\r\n'
      __paths=("${__paths[@]}" "$__path")
      __dists=("${__dists[@]}" "$RETURN_VALUE")

      #echo "$RETURN_VALUE: $__path; $__shell"
    done

    local __index __mindist=65535 # max distance

    # return path with existed minimal distance
    for (( __index=0; __index < ${#__paths[@]}; __index++ )); do
      __dist="${__dists[__index]}"
      if [[ -n "$__dist" ]] && (( __dist < __mindist )); then
        __path="${__paths[__index]}"
        __mindist=$__dist

        if (( ! __mindist )); then
          break
        fi
      fi
    done

    __is_found=$(( __mindist < 65535 ))

    tkl_restore_shopt
  fi

  if (( __is_found )); then
    eval "$__var=\"\$__path\""
  else
    eval "$__var=\"\$__value\""
  fi
}

if [[ -z "$BASH_LINENO" || BASH_LINENO[0] -eq 0 ]]; then
  # Script was not included, then execute it.
  detect_shell_userdir_file "$@"
fi
