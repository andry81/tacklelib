#!/bin/bash

# Description:
#   Script to allow rewrite in a bare git repository or in a list of git bare
#   repositories searched by the `find` pattern.

# Usage:
#   git_bare_config_allow_rewrite.sh <dir> [<name-pattern>]
#

# Script both for execution and inclusion.
if [[ -n "$BASH" ]]; then

function call()
{
  local IFS=$' \t'
  echo ">$*"
  "$@"
}

function git_bare_config_allow_rewrite()
{
  local dir="$1"
  local name_pttn="$2"

  local git_path

  if [[ -n "$name_pttn" ]]; then
    for git_path in `find "$dir" -name "$name_pttn" -type d`; do
      call pushd "$git_path" && {
        call git config receive.denynonfastforwards false
        call popd
      }
    done
  else
    call pushd "$dir" && {
      call git config receive.denynonfastforwards false
      call popd
    }
  fi

  return 0
}

# shortcut
function git_bc_arw()
{
  git_bare_config_allow_rewrite "$@"
}

if [[ -z "$BASH_LINENO" || BASH_LINENO[0] -eq 0 ]]; then
  # Script was not included, then execute it.
  git_bare_config_allow_rewrite "$@"
fi

fi
