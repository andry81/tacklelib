#!/bin/bash

# Description:
#   Script to replace user emails and names in all commits using
#   `git filter-branch` command.
#
#   The user email has priority over the user name, so if not matched, then
#   user name search is skipped. To avoid that you have to call function below
#   twice using `*` as an old value.

# Format:
#   git_filter_branch_user.sh author:committer email@to newname email@from oldname [email2@from oldname2 ...]
#   git-fb-u a:c email@to newname email@from oldname [email2@from oldname2 ...]
#

# Usage:
#   For single user email and name:
#
#   >
#   git filter-branch --env-filter \
#     "source '...path-to-file.../git_filter_branch_user.sh'; \
#     git_fb_u a:c '<USER_NEW_EMAIL>' '<USER_NEW_NAME>' '<USER_OLD_EMAIL>' '<USER_OLD_NAME>'" -- --all
#
#   For multiple user emails and names:
#
#   >
#   git filter-branch --env-filter \
#     "source '...path-to-file.../git_filter_branch_user.sh'; \
#     git_fb_u a:c '<USER_NEW_EMAIL>' '<USER_NEW_NAME>' '<USER_OLD_EMAIL_1>' '<USER_OLD_NAME_1>' '<USER_OLD_EMAIL_2>' '<USER_OLD_NAME_2>'" -- --all
#

# Script both for execution and inclusion.
if [[ -n "$BASH" ]]; then

function git_filter_branch_user()
{
  # list of types:
  #   author, committer, a, c
  # example:
  #   "a:c"
  local user_type_list="$1"

  local user_email_new="$2"
  local user_name_new="$3"

  local user_email_name_old_arr=("${@:4}") # pairs of email and name
  
  local user_email_old
  local user_name_old

  local user_author_email="$GIT_AUTHOR_EMAIL"
  local user_author_name="$GIT_AUTHOR_NAME"
  local user_committer_email="$GIT_COMMITTER_EMAIL"
  local user_committer_name="$GIT_COMMITTER_NAME"

  local i
  local IFS

  IFS=':'; for user_type in $user_type_list; do
    for (( i=0; i < ${#user_email_name_old_arr[@]}; i+=2 )); do
      user_email_old="${user_email_name_old_arr[i]}"
      user_name_old="${user_email_name_old_arr[i+1]}"

      case "$user_type" in
        'a' | 'author')
          if [[ "$user_email_old" == '*' || "$user_author_email" == "$user_email_old" ]]; then
            if [[ "$user_name_old" == '*' || "$user_author_name" == "$user_name_old" ]]; then
              if [[ "$user_email_new" != '*' ]]; then
                export GIT_AUTHOR_EMAIL="$user_email_new"
                #echo "GIT_AUTHOR_EMAIL=$GIT_AUTHOR_EMAIL"
              fi
              if [[ "$user_name_new" != '*' ]]; then
                export GIT_AUTHOR_NAME="$user_name_new"
                #echo "GIT_AUTHOR_NAME=$GIT_AUTHOR_NAME"
              fi
            fi
          fi
        ;;

        'c' | 'committer')
          if [[ "$user_email_old" == '*' || "$user_committer_email" == "$user_email_old" ]]; then
            if [[ "$user_name_old" == '*' || "$user_committer_name" == "$user_name_old" ]]; then
              if [[ "$user_email_new" != '*' ]]; then
                export GIT_COMMITTER_EMAIL="$user_email_new"
                #echo "GIT_COMMITTER_EMAIL=$GIT_COMMITTER_EMAIL"
              fi
              if [[ "$user_name_new" != '*' ]]; then
                export GIT_COMMITTER_NAME="$user_name_new"
                #echo "GIT_COMMITTER_NAME=$GIT_COMMITTER_NAME"
              fi
            fi
          fi
        ;;
      esac
    done
  done

  return 0
}

# shortcut
function git_fb_u()
{
  git_filter_branch_user "$@"
}

if [[ -z "$BASH_LINENO" || BASH_LINENO[0] -eq 0 ]]; then
  # Script was not included, then execute it.
  git_filter_branch_user "$@"
fi

fi
