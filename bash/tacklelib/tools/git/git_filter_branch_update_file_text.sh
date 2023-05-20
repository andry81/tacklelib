#!/bin/bash

# Description:
#   Script to update a file text from all commits in a repository
#   using `git filter-branch` command.
#   For search and replace functionality the `find` and `sed` utilities is
#   used.
#

# Usage:
#   git_filter_branch_update_file_text.sh <sourcetree-file-name-pattern> <text-to-match> <text-to-replace> [<cmd-line>]
#
#   <sourcetree-file-name-pattern>:
#     Source tree relative file pattern to a file to update.
#   <path-to-match>:
#     The `sed` text to match.
#   <text-to-replace>:
#     The `sed` text to replace.
#   <cmd-line>:
#     The rest of command line passed to `git filter-branch` command.

# Examples:
#   >
#   cd myrepo/path
#   git_filter_branch_update_file_text.sh README.md '<p/>' '</p>' -- --all
#
#   >
#   cd myrepo/path
#   git_filter_branch_update_file_text.sh README.md '<p/>' '</p>' -- master --not my-tag^@

# CAUTION:
#   Beware of line returns in Windows. Even if `sed` does not match the string,
#   it still can change the line returns of output lines. This brings an entire
#   file change without any match.

# NOTE:
#   The `git filter-repo` implementation does not support non exclusive file
#   filtering:
#     https://stackoverflow.com/questions/4110652/how-to-substitute-text-from-files-in-git-history/58252169#58252169
#
#     Using --path-glob (or --path) causes git filter-repo to only keep files
#     matching those specifications.
#
#   To workaround that you have to use the
#   `--replace-text-filename-callback` option which is a part of
#   `replace-text-limited-to-certain-files` branch implementation:
#     `Question: --replace-text only on certain files` :
#     https://github.com/newren/git-filter-repo/issues/74
#
#   But this one seems incomplete because of an exception throw:
#
#     `replace-text-limited-to-certain-files: TypeError: %d format: a real number is required, not bytes` :
#     https://github.com/newren/git-filter-repo/issues/468
#

# NOTE:
#   See all other details about rev-list caveats in the
#   `git_filter_branch_update_file.sh` file.

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

function git_filter_branch_update_file_text()
{
  local sourcetree_file_name_pttn="$1"
  local sed_text_to_match="$2"
  local sed_text_to_replace="$3"

  sed_text_to_match="${sed_text_to_match//\|/\\\|}"
  sed_text_to_replace="${sed_text_to_replace//\|/\\\|}"

  call git filter-branch --tree-filter "find . -name \"$sourcetree_file_name_pttn\" -type f -exec sed -i -e \
    \"s|$sed_text_to_match|$sed_text_to_replace|g\" {} \;" "${@:4}"
}

# shortcut
function git_fr_uft()
{
  git_filter_branch_update_file_text "$@"
}

if [[ -z "$BASH_LINENO" || BASH_LINENO[0] -eq 0 ]]; then
  # Script was not included, then execute it.
  git_filter_branch_update_file_text "$@"
fi

fi
