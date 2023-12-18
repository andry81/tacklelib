#!/bin/bash

# Description:
#   Script to replace commit message from all commits in a repository using
#   `git filter-repo` command:
#   https://github.com/newren/git-filter-repo
#   https://github.com/newren/git-filter-repo/tree/HEAD/Documentation/git-filter-repo.txt

# Usage:
#   git_filter_repo_replace_commit_msg.sh [flags] [//] <from-str> <to-str> [<cmd-line>]
#
#   <flags>:
#     -use-re-sub
#       Use `re.sub` instead of `msg.replace` as by default.
#
#     -re-sub-flags <re-sub-flags-python-expr>
#       Raw python expression string for `re.sub` flags parameter.
#       Has effect if `-use-re-sub` is used.
#       Ex: `re.DOTALL | ...`
#
#   //:
#     Separator to stop parse flags.
#
#   <from-str>
#     String to replace from.
#
#   <to-str>
#     String to replace to.
#
#   <cmd-line>:
#     The rest of command line passed to `git filter-repo` command.

# Examples:
#   # Removes `Update README.md` line from all commits.
#   >
#   cd myrepo/path
#   git_filter_repo_replace_commit_msg.sh "Update README.md"$'\n' "" --force
#
#   # Resets a line return characters before the `git-svn-id:[ \t]` string into
#   # a 2 line return characters.
#   >
#   cd myrepo/path
#   git_filter_repo_replace_commit_msg.sh -use-re-sub -re-sub-flags 're.DOTALL' '(\r\n|\n|\r)[\r\n]*(git-svn-id:[ \t])' '\1\1\2'
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

# NOTE:
#   You must use `git_filter_repo_cleanup.sh` script to complete the
#   operation and cleanup the repository from intermediate references.

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
  local flag="$1"

  local flag_use_re_sub=0
  local flag_re_sub_flags

  while [[ "${flag:0:1}" == '-' ]]; do
    flag="${flag:1}"

    if [[ "${flag:0:1}" == '-' ]]; then
      echo "$0: error: invalid flag: \`$flag\`" >&2
      return 255
    fi

    if [[ "$flag" == 'use-re-sub' ]]; then
      flag_use_re_sub=1
    elif [[ "$flag" == 're-sub-flags' ]]; then
      flag_re_sub_flags="$2"
      shift
    else
      echo "$0: error: invalid flag: \`$flag\`" >&2
      return 255
    fi

    shift

    flag="$1"
  done

  if [[ "$1" == '//' ]]; then
    shift
  fi

  export FROM_STR="$1"
  export TO_STR="$2"

  if ! (( flag_use_re_sub )); then
    call git filter-repo --commit-callback \
'import os, re
from_str = os.environ["FROM_STR"]
to_str = os.environ["TO_STR"]
msg = commit.message.decode("utf-8")
msg_new = msg.replace(from_str, to_str)
commit.message = msg_new.encode("utf-8")
' --partial "${@:3}"
  else
    export RE_SUB_FLAGS="$flag_re_sub_flags"
    call git filter-repo --commit-callback \
'import os, re
from_str = os.environ["FROM_STR"]
to_str = os.environ["TO_STR"]
re_sub_flags = os.environ["RE_SUB_FLAGS"]
if len(re_sub_flags):
  re_sub_flags = eval(re_sub_flags)
else:
  re_sub_flags = None
msg = commit.message.decode("utf-8")
msg_new = re.sub(from_str, to_str, msg, flags=re_sub_flags)
commit.message = msg_new.encode("utf-8")
' --partial "${@:3}"
  fi
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
