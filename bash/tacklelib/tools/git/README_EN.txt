* README_EN.txt
* 2023.02.20
* tacklelib--bash--git

1. DESCRIPTION
2. USAGE
3. AUTHOR

-------------------------------------------------------------------------------
1. DESCRIPTION
-------------------------------------------------------------------------------
The bash shell library for the `git filter-branch` command.

WARNING:
  Use the SVN access to find out latest functionality and bug fixes.
  See the REPOSITORIES section in the `README_EN.txt` file in the
  tacklelib project sources root.

-------------------------------------------------------------------------------
2. USAGE
-------------------------------------------------------------------------------

For single user name and email replace:

>
git filter-branch --env-filter \
  "source '...path-to-file.../git_filter_branch_lib.sh' && \
  git_filter_branch_committer_user '<USER_OLD_NAME>' '<USER_OLD_EMAIL>' '<USER_NEW_NAME>' '<USER_NEW_EMAIL>' && \
  git_filter_branch_author_user '<USER_OLD_NAME>' '<USER_OLD_EMAIL>' '<USER_NEW_NAME>' '<USER_NEW_EMAIL>'" -- --all

For multiple user name and email replace:

>
git filter-branch --env-filter \
  "source '...path-to-file.../git_filter_branch_lib.sh' && \
  git_filter_branch_committer_user '<USER_OLD_NAME_1>' '<USER_OLD_EMAIL_1>' '<USER_NEW_NAME_1>' '<USER_NEW_EMAIL_1>' && \
  git_filter_branch_author_user '<USER_OLD_NAME_1>' '<USER_OLD_EMAIL_1>' '<USER_NEW_NAME_1>' '<USER_NEW_EMAIL_1>' \
  git_filter_branch_committer_user '<USER_OLD_NAME_2>' '<USER_OLD_EMAIL_2>' '<USER_NEW_NAME_2>' '<USER_NEW_EMAIL_2>' && \
  git_filter_branch_author_user '<USER_OLD_NAME_2>' '<USER_OLD_EMAIL_2>' '<USER_NEW_NAME_2>' '<USER_NEW_EMAIL_2>'" -- --all

-------------------------------------------------------------------------------
3. AUTHOR
-------------------------------------------------------------------------------
Andrey Dibrov (andry at inbox dot ru)
