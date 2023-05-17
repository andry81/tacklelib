#!/bin/bash

# Description:
#   Script to cleanup artefacts after repository using `git filter-repo`
#   command:
#   https://github.com/newren/git-filter-repo

# Usage:
#   git_filter_repo_cleanup.sh
#

# Script both for execution and inclusion.
if [[ -n "$BASH" ]]; then

function evalcall()
{
  local IFS=$' \t'
  echo ">$*"
  eval "$@"
}

function git_filter_repo_cleanup()
{
  # based on: https://stackoverflow.com/questions/46229291/in-git-how-can-i-efficiently-delete-all-refs-matching-a-pattern/46229416#46229416
  evalcall "git for-each-ref --format='delete %(refname)' refs/replace | git update-ref --stdin"
}

# shortcut
function git_fr_cl()
{
  git_filter_repo_cleanup "$@"
}

if [[ -z "$BASH_LINENO" || BASH_LINENO[0] -eq 0 ]]; then
  # Script was not included, then execute it.
  git_filter_repo_cleanup "$@"
fi

fi
