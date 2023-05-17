#!/bin/bash

# Description:
#   Script to replace commit message from all commits in a repository using
#   `git filter-repo` command:
#   https://github.com/newren/git-filter-repo

# Usage:
#   git_filter_repo_replace_commit_msg.sh <from-str> <to-str> [<cmd-line>]
#
#   <cmd-line>:
#     The rest of command line passed to `git filter-repo` command.

# Examples:
#   >
#   cd myrepo/path
#   git_filter_repo_replace_commit_msg.sh "Update README.md"$'\n' "" --force
#

# NOTE:
#   The implementation implies the `--partial` flag to avoid remove of the
#   origin remote.
#
#   See details in the documentation:
#
#     https://htmlpreview.github.io/?https://github.com/newren/git-filter-repo/blob/docs/html/git-filter-repo.html#INTERNALS
#
#   --partial
#
#     Do a partial history rewrite, resulting in the mixture of old and new
#     history. This implies a default of update-no-add for --replace-refs,
#     disables rewriting refs/remotes/origin/* to refs/heads/*, disables
#     removing of the origin remote, disables removing unexported refs,
#     disables expiring the reflog, and disables the automatic post-filter gc.
#     Also, this modifies --tag-rename and --refname-callback options such that
#     instead of replacing old refs with new refnames, it will instead create
#     new refs and keep the old ones around. Use with caution.

# Script both for execution and inclusion.
if [[ -n "$BASH" ]]; then

function call()
{
  local IFS=$' \t'
  echo ">$*"
  "$@"
}

function git_filter_repo_replace_commit_msg()
{
  export FROM_STR="$1"
  export TO_STR="$2"

  call git filter-repo --commit-callback \
'import os, re
from_str = os.environ["FROM_STR"]
to_str = os.environ["TO_STR"]
msg = commit.message.decode("utf-8")
msg_new = msg.replace(from_str, to_str)
commit.message = msg_new.encode("utf-8")
' --partial "${@:3}"
}

# shortcut
function git_shcm_flr()
{
  git_filter_repo_replace_commit_msg "$@"
}

if [[ -z "$BASH_LINENO" || BASH_LINENO[0] -eq 0 ]]; then
  # Script was not included, then execute it.
  git_filter_repo_replace_commit_msg "$@"
fi

fi
