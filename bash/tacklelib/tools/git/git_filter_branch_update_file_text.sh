#!/bin/bash

# Description:
#   Script to update a file text from all commits in a repository
#   using `git filter-branch` command.
#   For search and replace functionality the `find` and `sed` utilities is
#   used.
#

# Usage:
#   git_filter_branch_update_file_text.sh [<flags>] [//] <sourcetree-file-name-pattern> <text-to-match> <text-to-replace> [<cmd-line>]
#
#   <flags>:
#     -E (POSIX)
#     -r
#       Use sed with extended regular expression.
#   //:
#     Separator to stop parse flags.
#   <sourcetree-file-name-pattern>:
#     Source tree relative file pattern to a file to update.
#   <path-to-match>:
#     The `sed` text to match.
#   <text-to-replace>:
#     The `sed` text to replace.
#   <cmd-line>:
#     The rest of command line passed to `git filter-branch` command.

# Examples:
#   # To update all commits in all heads to update first commit(s) in all
#   # ancestor branches.
#   >
#   cd myrepo/path
#   git_filter_branch_update_file_text.sh README.md '<p/>' '</p>' -- --all
#
#   # To update all commits by tag `t1` to update first commit(s) in all
#   # ancestor branches.
#   >
#   cd myrepo/path
#   git_filter_branch_update_file_text.sh README.md '<p/>' '</p>' -- t1
#
#   # To update single commit by a tag (excluding all parents).
#   >
#   cd myrepo/path
#   git_filter_branch_update_file_text.sh README.md '<p/>' '</p>' -- t1 --not t1^@
#
#   # To update master branch commits excluding tags.
#   >
#   cd myrepo/path
#   git_filter_branch_update_file_text.sh README.md '<p/>' '</p>' -- master ^t1 ^t2
#
#   # Remove multiline text with mixed line returns
#   >
#   cd myrepo/path
#   git_filter_branch_update_file_text.sh -E changelog.txt '2023\.05\.23:\r?\n[^\r\n]+\r?\n' '' -- master ^t1 ^t2

# CAUTION:
#   Beware of line returns in Windows. Even if `sed` does not match the string,
#   it still can change the line returns of output lines. This brings an entire
#   file change without any match.
#
#   So to workaround this the binary mode is always used:
#     https://stackoverflow.com/questions/4652652/preserve-line-endings

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
#   You must use `git_filter_branch_cleanup.sh` script to cleanup the
#   repository from intermediate references.

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
  local flag="$1"

  local flag_E=0
  local flag_r=0

  local sed_bare_flags=' -i -b'

  while [[ "${flag:0:1}" == '-' ]]; do
    flag="${flag:1}"

    if [[ "${flag:0:1}" == '-' ]]; then
      echo "$0: error: invalid flag: \`$flag\`" >&2
      return 255
    fi

    if [[ "${flag//E/}" != "$flag" ]]; then
      flag_E=1
      sed_bare_flags="$sed_bare_flags -E"
    elif [[ "${flag//r/}" != "$flag" ]]; then
      flag_r=1
      sed_bare_flags="$sed_bare_flags -r"
    else
      echo "$0: error: invalid flag: \`${flag:0:1}\`" >&2
      return 255
    fi

    shift

    flag="$1"
  done

  if [[ "$1" == '//' ]]; then
    shift
  fi

  local sourcetree_file_name_pttn="$1"
  local sed_text_to_match="$2"
  local sed_text_to_replace="$3"

  sed_text_to_match="${sed_text_to_match//\|/\\\|}"
  sed_text_to_replace="${sed_text_to_replace//\|/\\\|}"

  # Based on: https://unix.stackexchange.com/questions/182153/sed-read-whole-file-into-pattern-space-without-failing-on-single-line-input/182154#182154
  #
  # NOTE:
  #   `H;1h;\\\$!d;x;` reads portably whole file into pattern space.
  #
  call git filter-branch --tree-filter "find . -name \"$sourcetree_file_name_pttn\" -type f -exec sed$sed_bare_flags -e \
    \"H;1h;\\\$!d;x; s|$sed_text_to_match|$sed_text_to_replace|g\" {} \;" "${@:4}"
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
