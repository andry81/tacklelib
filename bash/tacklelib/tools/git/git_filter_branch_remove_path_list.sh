#!/bin/bash

# Description:
#   Script to remove path list from all commits in a repository using
#   `git filter-branch` command.

# Usage:
#   git_filter_branch_remove_path_list.sh [<flags>] [//] <path0> [... <pathN>] [// <cmd-line>]

#   <flags>:
#     --i0
#       Use `git update-index --index-info` to update entire index file.
#       By default.
#     --i1
#       Use `git update-index --remove` instead.
#     --i2
#       Use `git rm` instead of `git rm`.
#     -f
#       Use `git rm -f` or `git update-index --force-remove` respectively
#       instead. Is not applicable for the `--i0`.
#     -r
#       Use `git rm -r` respectively instead. Is not applicable for the `--i0`
#       and `--i1`.
#
#   //:
#     Separator to stop parse flags.
#   <path0> [... <pathN>]:
#     Source tree relative file paths to a file/directory to remove.
#   //:
#     Separator to stop parse path list.
#   <cmd-line>:
#     The rest of command line passed to `git filter-branch` command.

# Examples:
#   >
#   cd myrepo/path
#   git_filter_branch_remove_path_list.sh dir1/ file1 file2/ dir-or-file // -- dev ^t1 ^master
#
#   NOTE:
#     * `dir1`            - (dir) removed
#     * `dir1/dir2`       - (dir) removed
#     * `dir1/dir2/file1` - (file) removed
#     * `dir2/dir1`       - (dir) NOT removed
#     * `file1`           - (file) removed
#     * `dir2/file1`      - (file) NOT removed
#     * `file2`           - (file) NOT removed
#     * `dir-or-file`     - (file/dir) removed

# Examples:
#   # To update all commits in all heads to update first commit(s) in all
#   # ancestor branches.
#   >
#   cd myrepo/path
#   git_filter_branch_remove_path_list.sh ... -- --all
#
#   # To update all commits by tag `t1` to update first commit(s) in all
#   # ancestor branches.
#   >
#   cd myrepo/path
#   git_filter_branch_remove_path_list.sh ... -- t1
#
#   # To update single commit by a tag.
#   >
#   cd myrepo/path
#   git_filter_branch_remove_path_list.sh ... -- t1 --not t1^@
#
#   >
#   cd myrepo/path
#   git_filter_branch_remove_path_list.sh ... -- t1^!

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
#   child/children and has changes, then the script does remove an existing
#   file including children commits changes. This means that the changes in
#   all child branches would be lost.
#
#   But if you want to remove a file in all commits before a commit, then you
#   have to limit the `rev-list` parameter by that commit.

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

function git_filter_branch_remove_path_list()
{
  local flag="$1"

  local option_i=0
  local flag_f=0
  local flag_r=0
  local skip_flag

  while [[ "${flag:0:1}" == '-' ]]; do
    flag="${flag:1}"
    skip_flag=0

    if [[ "$flag" == '-i0' ]]; then
      skip_flag=1
    elif [[ "$flag" == '-i1' ]]; then
      option_i=1
      skip_flag=1
    elif [[ "$flag" == '-i2' ]]; then
      option_i=2
      skip_flag=1
    elif [[ "${flag:0:1}" == '-' ]]; then
      echo "$0: error: invalid flag: \`$flag\`" >&2
      return 255
    fi

    if (( ! skip_flag )); then
      if [[ "${flag//f/}" != "$flag" ]]; then
        flag_f=1
      elif [[ "${flag//r/}" != "$flag" ]]; then
        flag_r=1
      else
        echo "$0: error: invalid flag: \`${flag:0:1}\`" >&2
        return 255
      fi
    fi

    shift

    flag="$1"
  done

  if [[ "$1" == '//' ]]; then
    shift
  fi

  local rm_bare_flags=''

  # insert an option before instead of after
  case $option_i in
    0)
      if (( flag_f )); then
        echo "$0: error: flag is not applicable: \`f\`" >&2
        return 255
      fi
      if (( flag_r )); then
        echo "$0: error: flag is not applicable: \`r\`" >&2
        return 255
      fi
      ;;
    1)
      if (( flag_r )); then
        echo "$0: error: flag is not applicable: \`r\`" >&2
        return 255
      fi
      if (( ! flag_f )); then
        rm_bare_flags=" --remove$rm_bare_flags"
      else
        rm_bare_flags=" --force-remove$rm_bare_flags"
      fi
      ;;
    2)
      if (( flag_f )); then
        rm_bare_flags=" -f$rm_bare_flags"
      fi
      if (( flag_r )); then
        rm_bare_flags=" -r$rm_bare_flags"
      fi
      ;;
  esac

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

    if [[ -n "$arg" ]]; then
      path_list_cmdline="$path_list_cmdline \"$arg\""
    fi

    shift

    arg="$1"
  done

  if [[ -z "$path_list_cmdline" ]]; then
    return 255
  fi

  export PATH_LIST_CMDLINE="$path_list_cmdline"

  case $option_i in
    0)
      call git filter-branch --index-filter \
'eval "path_arr=($PATH_LIST_CMDLINE)"
git ls-files -s "${path_arr[@]}" | {
  while IFS=$'\'' \t'\'' read mode hash stage path; do
    echo "0 0000000000000000000000000000000000000000	$path"
  done | git update-index --index-info
}' \
        "$@"
      ;;
    1)
      call git filter-branch --index-filter \
'eval "path_arr=($PATH_LIST_CMDLINE)"
git update-index'"$rm_bare_flags"' "${path_arr[@]}"' "$@"
      ;;
    2)
      call git filter-branch --index-filter \
'eval "path_arr=($PATH_LIST_CMDLINE)"
git rm'"$rm_bare_flags"' "${path_arr[@]}"' "$@"
      ;;
  esac
}

# shortcut
function git_fb_rpl()
{
  git_filter_branch_remove_path_list "$@"
}

if [[ -z "$BASH_LINENO" || BASH_LINENO[0] -eq 0 ]]; then
  # Script was not included, then execute it.
  git_filter_branch_remove_path_list "$@"
fi

fi
