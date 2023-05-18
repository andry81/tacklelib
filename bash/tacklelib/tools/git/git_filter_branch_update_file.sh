#!/bin/bash

# Description:
#   Script to update (add or replace) a file from all commits in a repository
#   using `git filter-branch` command.
#

# Usage:
#   git_filter_branch_update_file.sh <path-to-file> <sourcetree-path-to-dir> [<cmd-line>]
#
#   <path-to-file>:
#     Local file path to add.
#   <sourcetree-path-to-dir>:
#     Source tree relative file path to a directory.
#   <cmd-line>:
#     The rest of command line passed to `git filter-repo` command.

# CAUTION:
#   Path `<path-to-file>` must be outside of the working copy, otherwise the
#   git will complain about unstaged changes:
#   `Cannot rewrite branches: You have unstaged changes.`
#   This happens because in that case the `<path-to-file>` is changed or a new
#   file.

# Examples:
#   # To update all commits by a tag to update first commit(s) in all ancestor
#   # branches.
#   >
#   cd myrepo/path
#   git_filter_branch_update_file.sh ../blabla/.empty-dummy . -- --all
#
#   # To update single commit by a tag to update the last commit.
#   >
#   cd myrepo/path
#   git_filter_branch_update_file.sh ../blabla/.empty-dummy . -- my-tag~1..my-tag

# NOTE:
#   You must use `git_filter_branch_cleanup.sh` script to complete the
#   operation and cleanup the repository from intermediate references.

# Based on:
#   https://stackoverflow.com/questions/21353584/git-how-do-i-add-a-file-to-the-first-commit-and-rewrite-history-in-the-process
#

# Script both for execution and inclusion.
if [[ -n "$BASH" ]]; then

function call()
{
  local IFS=$' \t'
  echo ">$*"
  "$@"
}

function git_filter_branch_update_file()
{
  local local_path="${1//\\//}"
  local sourcetree_path_dir="${2//\\//}"

  local local_path_file_name="${local_path##*/}"

  call git filter-branch --index-filter "cp \"$local_path\" \"$sourcetree_path_dir\" && git update-index --add \"$sourcetree_path_dir/$local_path_file_name\"" "${@:3}"
}

# shortcut
function git_fb_af()
{
  git_filter_branch_update_file "$@"
}

if [[ -z "$BASH_LINENO" || BASH_LINENO[0] -eq 0 ]]; then
  # Script was not included, then execute it.
  git_filter_branch_update_file "$@"
fi

fi
