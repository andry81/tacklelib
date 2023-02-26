#!/bin/bash

# Description:
#   Script to unmirror all local refs in all remotes.

# Usage:
#   git_unmirror_refs.sh
#

# Script both for execution and inclusion.
if [[ -n "$BASH" ]]; then

function call()
{
  local IFS=$' \t'
  echo ">$*"
  "$@"
}

function git_unmirror_refs()
{
  # print all remotes
  call git remote || exit 255
  echo ---

  # Pull to update local references and test on unmerged heads in the local.
  IFS=$'\n\r'; for remote in `git remote 2>/dev/null`; do
    call git pull "$remote" '*:*'
    echo ---
    echo
  done

  # print all refs
  call git show-ref || exit 255
  echo ---

  local IFS

  local hash
  local ref

  local git_push_cmdline

  IFS=$'\n\r'; for remote in `git remote 2>/dev/null`; do
    [[ -z "$remote" ]] && continue
    git_push_cmdline=''
    IFS=$' \t'; while read -r hash ref; do
      [[ "${ref:0:13}" != "refs/remotes/" ]] && continue
      ref_remote="${ref:13}"
      [[ -z "$ref_remote" ]] && continue
      git_push_cmdline="$git_push_cmdline ':refs/remotes/$ref_remote'"
    done <<< `git show-ref 2>/dev/null`
    if [[ -n "$git_push_cmdline" ]]; then
      eval call git push \"\$remote\" $git_push_cmdline
      echo ---
      echo
    fi
  done

  # Remove all local refs to recreate them in the last pull.
  IFS=$' \t'; while read -r hash ref; do
    [[ "${ref:0:13}" != "refs/remotes/" ]] && continue
    ref_remote="${ref:13}"
    [[ -z "$ref_remote" ]] && continue
    call git update-ref -d "$ref"
  done <<< `git show-ref 2>/dev/null`
  echo ---
  echo

  # Pull to update local references and test on unmerged heads in the local.
  IFS=$'\n\r'; for remote in `git remote 2>/dev/null`; do
    call git pull "$remote" '*:*'
    echo ---
    echo
  done

  return 0
}

# shortcut
function git_ur()
{
  git_unmirror_refs "$@"
}

if [[ -z "$BASH_LINENO" || BASH_LINENO[0] -eq 0 ]]; then
  # Script was not included, then execute it.
  git_unmirror_refs "$@"
fi

fi
