#!/bin/bash

# Description:
#   Script to update (add or replace) a file from all commits in a repository
#   using `git filter-branch` command.
#

# Usage:
#   git_filter_branch_update_file.sh <path-to-file> <sourcetree-path-to-dir> [<cmd-line>]
#
#   <path-to-file>:
#     Local file path to update.
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
#   # To update single commit by a tag.
#   >
#   cd myrepo/path
#   git_filter_branch_update_file.sh ../blabla/.empty-dummy . -- my-tag --not my-tag^@
#
#   >
#   cd myrepo/path
#   git_filter_branch_update_file.sh ../blabla/.empty-dummy . -- my-tag^!

# CAUTION:
#   In a generic case the `rev-list` parameter of the `git filter-branch`
#   command must be a set of commit ranges to rewrite a single commit or a set
#   of commits. This is required because a commit in the commits tree can has
#   multiple parent commits and to select a single commit with multiple parents
#   (merge commit) you must issue a range of commits for EACH PARENT to define
#   range in each parent branch.
#
#   In other words a single expression `<obj>~1..<ref>` does not guarantee a
#   selection of a single commit if `<ref>` points a commit with multiple
#   parents or has it on a way over other commits to the `<obj>`.
#   The same for the `<ref> --not <obj>^@` or `<obj>^@..<ref>` expression if
#   the path between `<ref>` and `<obj>` contains more than 1 commit. In that
#   particular case to select a single commit you must use multiple ranges.
#
#   If `<ref>` and `<obj>` points the same commit (range for a single), then
#   the `<ref> --not <obj>^@` or `<obj>^@..<ref>` or `<ref>^!` is enough to
#   always select a single commit in any tree.

# CAUTION:
#   If a file already exist in a being updated commit or in a commit
#   child/children and has changes, then the script does replace an existing
#   file including children commits changes. This means that the changes in
#   all child branches would be lost.
#
#   https://stackoverflow.com/questions/54199584/how-to-add-a-file-to-a-specific-commit-with-git-filter-branch/76288099#76288099
#
#   If you are trying to replace a file and it has changes in next child
#   commit(s), for example, `changelog.txt` file, then you must rewrite it in
#   each next child, otherwise the next commits will be left with old file.
#   In that case actual to use `git filter-repo` with file text search and
#   replace instead of a file add/replace or manually rewrite each next child
#   commit before call to `git replace --graft ...`.

# NOTE:
#   You must use `git_filter_branch_cleanup.sh` script to complete the
#   operation and cleanup the repository from intermediate references.

# Based on:
#   https://stackoverflow.com/questions/54199584/how-to-add-a-file-to-a-specific-commit-with-git-filter-branch
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
function git_fb_uf()
{
  git_filter_branch_update_file "$@"
}

if [[ -z "$BASH_LINENO" || BASH_LINENO[0] -eq 0 ]]; then
  # Script was not included, then execute it.
  git_filter_branch_update_file "$@"
fi

fi
