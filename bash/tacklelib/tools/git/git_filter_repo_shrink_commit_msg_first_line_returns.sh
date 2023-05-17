#!/bin/bash

# Description:
#   Script to shrink first line returns (remove all line returns before the
#   first line and shrink repeating line returns after the first line) from all
#   commits in a repository using `git filter-repo` command:
#   https://github.com/newren/git-filter-repo

# Usage:
#   git_filter_repo_shrink_commit_msg_first_line_returns.sh [<cmd-line>]
#
#   <cmd-line>:
#     The rest of command line passed to `git filter-repo` command.

# Examples:
#   >
#   cd myrepo/path
#   git_filter_repo_shrink_commit_msg_first_line_returns.sh --force
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

# CAUTION:
#   DO NOT USE `$` as an end single string matcher here.
#   It does not follow the last line return!
#
function git_filter_repo_shrink_commit_msg_first_line_returns()
{
  call git filter-repo --commit-callback \
'import re
msg = commit.message.decode("utf-8")
msg_new = re.sub(r'\''^[\r\n]*([^\r\n]+)(\r\n|\n|\r)?[\r\n]*(.*)'\'', r'\''\1\2\3'\'', msg, flags=re.DOTALL)
commit.message = msg_new.encode("utf-8")
' --partial "$@"
}

# shortcut
function git_shcm_flr()
{
  git_filter_repo_shrink_commit_msg_first_line_returns "$@"
}

if [[ -z "$BASH_LINENO" || BASH_LINENO[0] -eq 0 ]]; then
  # Script was not included, then execute it.
  git_filter_repo_shrink_commit_msg_first_line_returns "$@"
fi

fi
