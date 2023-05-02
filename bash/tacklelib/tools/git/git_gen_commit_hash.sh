#!/bin/bash

# Description:
#   Script to generate a commit hash from hash or reference.
#   Useful to recheck a commit consistency.

# Usage:
#   git_gen_commit_hash.sh [<flags>] [//] <object> [<hash-cmd> [<hash-cmd-line>]]
#
#   <flags>:
#     -p
#       Include print parents for each commit.
#   //:
#     Separator to stop parse flags.
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
  local flag="$1"

  local flag_print_parents=0

  while [[ "${flag:0:1}" == '-' ]]; do
    flag="${flag:1}"

    if [[ "${flag:0:1}" == '-' ]]; then
      echo "$0: error: invalid flag: \`$flag\`"
      exit 255
    fi

    while [[ -n "$flag" ]]; do
      if [[ "${flag//p/}" != "$flag" ]]; then
        flag_print_parents=1
        flag="${flag//p/}"
      else
        echo "$0: error: invalid flag: \`${flag:0:1}\`"
        exit 255
      fi
    done

    shift

    flag="$1"
  done

  if [[ "$1" == '//' ]]; then
    shift
  fi

  local obj="$1"
  local hashcmd="$2"
  local hashcmdline=("${@:3}")

  if [[ -z "$hashcmd" || "$hashcmd" == '.' ]]; then
    hashcmd=("sha1sum")
  fi

  local line

  local objtype parenthash
  local hashsum
  local hashvalue suffix

  local IFS

  objtype="$(git cat-file -t "$obj")"
  hashsum="$(echo -ne "$objtype $(git cat-file -s "$obj")\0$(git cat-file -p "$obj")" | $hashcmd "${hashcmdline[@]}")"

  IFS=$'\t ' read -r hashvalue suffix <<< "$hashsum"

  echo "$hashvalue $(git rev-parse "$obj") $objtype $obj"

  if (( flag_print_parents )); then
    IFS=$'\n\r'; for line in `git rev-parse "$obj^@"`; do
      IFS=$'\t ' read -r parenthash suffix <<< "$line"

      objtype="$(git cat-file -t "$parenthash")"
      hashsum="$(echo -ne "$objtype $(git cat-file -s "$parenthash")\0$(git cat-file -p "$parenthash")" | $hashcmd "${hashcmdline[@]}")"

      IFS=$'\t ' read -r hashvalue suffix <<< "$hashsum"

      echo "$hashvalue $parenthash $objtype"
    done
  fi
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
