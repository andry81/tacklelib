#!/bin/bash

# Description:
#   Script to deny rewrite in a bare git repository or in a list of git bare
#   repositories searched by the `find` pattern.

# Usage:
#   git_bare_config_deny_rewrite.sh <dir> [<dir-name-pattern>]

# Examples:
#   >
#   git_bare_config_deny_rewrite.sh /home/git "*.git"
#

# Script both for execution and inclusion.
if [[ -n "$BASH" ]]; then

function call()
{
  local IFS=$' \t'
  echo ">$*"
  "$@"
}

# Based on:
#   https://stackoverflow.com/questions/71928010/makefile-on-windows-is-there-a-way-to-force-make-to-use-the-mingw-find-exe/76393735#76393735
#
function detect_find()
{
  SHELL_FIND=find

  # detect `find.exe` in Windows behind `$SYSTEMROOT\System32\find.exe`
  if which where >/dev/null 2>&1; then
    for path in `where find 2>/dev/null`; do
      case "$path" in
        "$SYSTEMROOT"\\*) ;;
        "$WINDIR"\\*) ;;
        *)
          SHELL_FIND="$path"
          break
          ;;
      esac
    done
  fi
}

function git_bare_config_deny_rewrite()
{
  local dir="$1"
  local name_pttn="$2"

  local git_path

  if [[ -n "$name_pttn" ]]; then
    detect_find

    for git_path in `find "$dir" -name "$name_pttn" -type d`; do
      call pushd "$git_path" && {
        call git config receive.denynonfastforwards true
        call popd
      }
    done
  else
    call pushd "$dir" && {
      call git config receive.denynonfastforwards true
      call popd
    }
  fi

  return 0
}

# shortcut
function git_bc_drw()
{
  git_bare_config_deny_rewrite "$@"
}

if [[ -z "$BASH_LINENO" || BASH_LINENO[0] -eq 0 ]]; then
  # Script was not included, then execute it.
  git_bare_config_deny_rewrite "$@"
fi

fi
