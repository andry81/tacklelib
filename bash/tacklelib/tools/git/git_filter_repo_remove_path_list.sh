#!/bin/bash

# Description:
#   Script to remove path list from all commits in a repository using
#   `git filter-repo` command:
#   https://github.com/newren/git-filter-repo
#   https://github.com/newren/git-filter-repo/tree/HEAD/Documentation/git-filter-repo.txt

# Usage:
#   git_filter_repo_remove_path_list.sh <path0> [... <pathN>] [// <cmd-line>]
#
#   <path0> [... <pathN>]:
#     Paths to remove.
#   //:
#     Separator to stop parse path list.
#   <cmd-line>:
#     The rest of command line passed to `git filter-repo` command.

# Examples:
#   >
#   cd myrepo/path
#   git_filter_repo_remove_path_list.sh mydir/ myfile.txt // --force
#
#   CAUTION:
#     In example above all paths has contained `mydir` and `myfile` will be
#     removed:
#     * `mydir/`
#     * `mydir/dir1`
#     * `mydir/dir1/file1`
#     * `myfile`
#     * `dir1/myfile`

# NOTE:
#   You must use `git_filter_repo_cleanup.sh` script to complete the
#   operation and cleanup the repository from intermediate references.

# Script both for execution and inclusion.
if [[ -n "$BASH" ]]; then

function evalcall0()
{
  local IFS=$' \t'
  echo ">$*"
  eval "$1 \"\${@:2}\""
}

function git_filter_repo_remove_path_list()
{
  local arg
  local args=("$@")
  local path_list_cmdline=''
  local num_args=${#args[@]}
  local i

  for (( i=0; i < num_args; i++ )); do
    arg="${args[i]}"

    if [[ "$arg" == '//' ]]; then
      shift
      break
    fi

    path_list_cmdline="$path_list_cmdline --path \"$arg\""
    shift
    arg="$1"
  done

  if [[ -z "$path_list_cmdline" ]]; then
    return 255
  fi

  evalcall0 "git filter-repo --invert-paths$path_list_cmdline" "$@"
}

# shortcut
function git_fr_rpl()
{
  git_filter_repo_remove_path_list "$@"
}

if [[ -z "$BASH_LINENO" || BASH_LINENO[0] -eq 0 ]]; then
  # Script was not included, then execute it.
  git_filter_repo_remove_path_list "$@"
fi

fi
