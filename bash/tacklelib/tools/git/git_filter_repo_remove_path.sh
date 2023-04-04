#!/bin/bash

# Description:
#   Script to remove path from all commits in a repository using
#   `git-filter-repo` script:
#   https://github.com/newren/git-filter-repo

# Usage:
#   git_filter_repo_remove_path.sh <path> <cmd-line>
#
#   <path>:
#     Path to remove.
#   <cmd-line>:
#     The rest of command line passed to `git-filter-repo` script.

# Script both for execution and inclusion.
if [[ -n "$BASH" ]]; then

function call()
{
  local IFS=$' \t'
  echo ">$*"
  "$@"
}

function git_filter_repo_remove_path()
{
  local path="$1"

  git-filter-repo --invert-paths --path "$path" "${@:2}"

  return 0
}

# shortcut
function git_fr_rp()
{
  git_filter_repo_remove_path "$@"
}

if [[ -z "$BASH_LINENO" || BASH_LINENO[0] -eq 0 ]]; then
  # Script was not included, then execute it.
  git_filter_repo_remove_path "$@"
fi

fi
