#!/bin/bash

function git_filter_branch_committer_user()
{
  local USER_OLD_NAME="$1"
  local USER_OLD_EMAIL="$2"
  local USER_NEW_NAME="$3"
  local USER_NEW_EMAIL="$4"

  if [[ -z "$USER_OLD_NAME" && -z "$USER_OLD_EMAIL" ]]; then
    echo "$0: error: at least USER_OLD_NAME or USER_OLD_EMAIL must be not empty" >&2
    return 255
  fi

  if [[ -z "$USER_NEW_NAME" && -z "$USER_NEW_EMAIL" ]]; then
    echo "$0: error: at least USER_NEW_NAME or USER_NEW_EMAIL must be not empty" >&2
    return 255
  fi

  [[ -z "$USER_NEW_NAME" ]] && USER_NEW_NAME="$USER_OLD_NAME"
  [[ -z "$USER_NEW_EMAIL" ]] && USER_NEW_EMAIL="$USER_OLD_EMAIL"

  local update_committer_name=0
  local update_committer_email=0

  [[ -n "$GIT_COMMITTER_NAME" && -n "$USER_OLD_NAME" && ( "$USER_OLD_NAME" == "*" || "$GIT_COMMITTER_NAME" == "$USER_OLD_NAME" ) ]] &&        update_committer_name=1
  [[ -n "$GIT_COMMITTER_EMAIL" && -n "$USER_OLD_EMAIL" && ( "$USER_OLD_EMAIL" == "*" || "$GIT_COMMITTER_EMAIL" == "$USER_OLD_EMAIL" ) ]] &&   update_committer_email=1

  (( update_committer_name )) && export GIT_COMMITTER_NAME="$USER_NEW_NAME"
  (( update_committer_email )) && export GIT_COMMITTER_EMAIL="$USER_NEW_EMAIL"

  return 0
}

function git_filter_branch_author_user()
{
  local USER_OLD_NAME="$1"
  local USER_OLD_EMAIL="$2"
  local USER_NEW_NAME="$3"
  local USER_NEW_EMAIL="$4"

  if [[ -z "$USER_OLD_NAME" && -z "$USER_OLD_EMAIL" ]]; then
    echo "$0: error: at least USER_OLD_NAME or USER_OLD_EMAIL must be not empty" >&2
    return 255
  fi

  if [[ -z "$USER_NEW_NAME" && -z "$USER_NEW_EMAIL" ]]; then
    echo "$0: error: at least USER_NEW_NAME or USER_NEW_EMAIL must be not empty" >&2
    return 255
  fi

  [[ -z "$USER_NEW_NAME" ]] && USER_NEW_NAME="$USER_OLD_NAME"
  [[ -z "$USER_NEW_EMAIL" ]] && USER_NEW_EMAIL="$USER_OLD_EMAIL"

  local update_author_name=0
  local update_author_email=0

  [[ -n "$GIT_AUTHOR_NAME" && -n "$USER_OLD_NAME" && ( "$USER_OLD_NAME" == "*" || "$GIT_AUTHOR_NAME" == "$USER_OLD_NAME" ) ]] &&        update_author_name=1
  [[ -n "$GIT_AUTHOR_EMAIL" && -n "$USER_OLD_EMAIL" && ( "$USER_OLD_EMAIL" == "*" || "$GIT_AUTHOR_EMAIL" == "$USER_OLD_EMAIL" ) ]] &&   update_author_email=1

  (( update_author_name )) && export GIT_AUTHOR_NAME="$USER_NEW_NAME"
  (( update_author_email )) && export GIT_AUTHOR_EMAIL="$USER_NEW_EMAIL"

  return 0
}
