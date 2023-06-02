#!/bin/bash

# Description:
#   Script to remove a path from all commits in a repository using
#   `git filter-repo` command:
#   https://github.com/newren/git-filter-repo
#   https://github.com/newren/git-filter-repo/tree/HEAD/Documentation/git-filter-repo.txt

# Usage:
#   git_filter_repo_remove_path.sh <path> [<cmd-line>]
#
#   <path>:
#     Source tree relative file path to a file/directory to remove.
#   <cmd-line>:
#     The rest of command line passed to `git filter-repo` command.

# CAUTION:
#   Currently the `git filter-repo` implementation is not stable and may miss
#   to remove paths:
#
#   * `--invert-path does not invert path beginning a commit` :
#     https://github.com/newren/git-filter-repo/issues/473
#
#   To avoid that use `git_filter_branch_remove_path.sh` script instead.

# Examples:
#   >
#   cd myrepo/path
#   git_filter_repo_remove_path.sh dir1/ --refs dev ^t1 ^master --force
#
#   NOTE:
#     * `dir1`            - (dir) removed
#     * `dir1/dir2`       - (dir) removed
#     * `dir1/dir2/file1` - (file) removed
#     * `dir2/dir1`       - (dir) NOT removed
#
#   >
#   cd myrepo/path
#   git_filter_repo_remove_path.sh file1 --refs dev ^t1 ^master --force
#
#   NOTE:
#     * `file1`           - (file) removed
#     * `dir1/file1`      - (file) NOT removed
#
#   >
#   cd myrepo/path
#   git_filter_repo_remove_path.sh file2/ --refs dev ^t1 ^master --force
#
#   NOTE:
#     * `file2`           - (file) NOT removed
#
#   >
#   cd myrepo/path
#   git_filter_repo_remove_path.sh dir-or-file --refs dev ^t1 ^master --force
#
#   NOTE:
#     * `dir-or-file`     - (file/dir) removed
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

function git_filter_repo_remove_path()
{
  local path="$1"

  call git filter-repo --partial --invert-paths --path "$path" "${@:2}"
}

# shortcut
function git_fr_rp()
{
  git_filter_repo_remove_path "$@"
}

if [[ -z "$BASH_LINENO" || BASH_LINENO[0] -eq 0 ]]; then
  # Script was not included, then execute it.
  git_filter_repo_remove_path "$@"
fi

fi
