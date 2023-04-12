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

function git_bare_config_deny_rewrite()
{
  local dir="$1"
  local name_pttn="$2"

  local git_path

  if [[ -n "$name_pttn" ]]; then
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
