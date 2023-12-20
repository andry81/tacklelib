#!/bin/bash

# Description:
#   Script to complete the last operation and cleanup artefacts after using
#   `subgit import ...` command:
#   https://subgit.com/documentation/howto.html#import

# Usage:
#   git_subgit_svn_import_cleanup.sh
#

# Script both for execution and inclusion.
if [[ -n "$BASH" ]]; then

function evalcall()
{
  local IFS=$' \t'
  echo ">$*"
  eval "$@"
}

function git_subgit_svn_import_cleanup()
{
  # based on: https://stackoverflow.com/questions/46229291/in-git-how-can-i-efficiently-delete-all-refs-matching-a-pattern/46229416#46229416
  evalcall "git for-each-ref --format='delete %(refname)' refs/notes/commits | git update-ref --stdin"
  evalcall "git for-each-ref --format='delete %(refname)' refs/svn/history | git update-ref --stdin"
  evalcall "git for-each-ref --format='delete %(refname)' refs/svn/map | git update-ref --stdin"
  evalcall "git for-each-ref --format='delete %(refname)' refs/svn/root | git update-ref --stdin"
}

# shortcut
function git_sg_si_cl()
{
  git_subgit_svn_import_cleanup "$@"
}

if [[ -z "$BASH_LINENO" || BASH_LINENO[0] -eq 0 ]]; then
  # Script was not included, then execute it.
  git_subgit_svn_import_cleanup "$@"
fi

fi
