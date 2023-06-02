#!/bin/bash

# Description:
#   Script to cleanup artefacts after using `git filter-branch` command.

# Usage:
#   git_filter_branch_cleanup.sh
#

# Script both for execution and inclusion.
if [[ -n "$BASH" ]]; then

function call()
{
  local IFS=$' \t'
  echo ">$*"
  "$@"
}

function git_filter_branch_cleanup()
{
  # print all refs
  call git show-ref || return 255
  echo ---

  local IFS

  local hash
  local ref

  # remove all original refs
  IFS=$' \t'; while read -r hash ref; do
    [[ "${ref:0:19}" != "refs/original/refs/" ]] && continue
    ref_remote="${ref:19}"
    [[ -z "$ref_remote" ]] && continue
    call git update-ref -d "$ref"
  done <<< `git show-ref 2>/dev/null`

  return 0
}

# shortcut
function git_fb_cl()
{
  git_filter_branch_cleanup "$@"
}

if [[ -z "$BASH_LINENO" || BASH_LINENO[0] -eq 0 ]]; then
  # Script was not included, then execute it.
  git_filter_branch_cleanup "$@"
fi

fi
