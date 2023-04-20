#!/bin/bash

# Description:
#   Script to shrink first line returns (remove all line returns before the
#   first line and shrink repeating line returns after the first line) from all
#   commits in a repository using `git-filter-repo` script:
#   https://github.com/newren/git-filter-repo

# Usage:
#   git_filter_repo_shrink_commit_msg_first_line_returns.sh <cmd-line>
#
#   <cmd-line>:
#     The rest of command line passed to `git-filter-repo` script.

# Examples:
#   >
#   cd myrepo/path
#   git_filter_repo_shrink_commit_msg_first_line_returns.sh --force
#

# Script both for execution and inclusion.
if [[ -n "$BASH" ]]; then

function call()
{
  local IFS=$' \t'
  echo ">$*"
  "$@"
}

function git_filter_repo_shrink_commit_msg_first_line_returns()
{
  call git-filter-repo --commit-callback \
'import re
msg = commit.message.decode("utf-8")
msg_new = re.sub(r'\''[\r\n]*([^\r\n]+)(\r?\n)[\r\n]*?(.*)'\'', r'\''\1\2\3'\'', msg)
commit.message = msg_new.encode("utf-8")
' "$@"

  return 0
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
