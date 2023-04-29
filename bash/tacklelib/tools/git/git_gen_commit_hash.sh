#!/bin/bash

# Description:
#   Script to generate a commit hash from hash or reference.
#   Useful to recheck a commit consistency.

# Usage:
#   git_gen_commit_hash.sh <object> [<hash-cmd> [<hash-cmd-line>]]
#
#   <object>:
#     A commit hash or reference.
#   <hash-cmd>:
#     The hash command to execute for stdin pipe.
#     If not defined, then `sha1sum` is used.
#   <hash-cmd-line>:
#     The hash command line for `<hash-cmd>` command.

# Examples:
#   >
#   cd myrepo/path
#   git_gen_commit_hash.sh master
#
#   >
#   cd myrepo/path
#   git_gen_commit_hash.sh master . -b
#
#   >
#   cd myrepo/path
#   git_gen_commit_hash.sh master git hash-object --stdin

# Script both for execution and inclusion.
if [[ -n "$BASH" ]]; then

function git_gen_commit_hash()
{
  local obj="$1"
  local hashcmd="$2"
  local hashcmdline=("${@:3}")

  if [[ -z "$hashcmd" || "$hashcmd" == '.' ]]; then
    hashcmd=("sha1sum")
  fi

  local objtype="$(git cat-file -t "$obj")"
  local hashsum="$(echo -ne "$objtype $(git cat-file -s "$obj")\0$(git cat-file -p "$obj")" | $hashcmd "${hashcmdline[@]}")"
  local hashvalue suffix

  local IFS

  IFS=$'\t ' read -r hashvalue suffix <<< "$hashsum"

  echo "$hashvalue $(git rev-parse "$obj") $objtype $obj"
}

# shortcut
function git_gch()
{
  git_gen_commit_hash "$@"
}

if [[ -z "$BASH_LINENO" || BASH_LINENO[0] -eq 0 ]]; then
  # Script was not included, then execute it.
  git_gen_commit_hash "$@"
fi

fi
