* README_EN.txt
* 2020.09.04
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

>
git filter-branch --env-filter \
  "source '...path-to-file.../git_filter_branch_lib.sh' && \
  git_filter_branch_committer_user '<USER_OLD_NAME>' '<USER_OLD_EMAIL>' '<USER_NEW_NAME>' '<USER_NEW_EMAIL>' && \
  git_filter_branch_author_user '<USER_OLD_NAME>' '<USER_OLD_EMAIL>' '<USER_NEW_NAME>' '<USER_NEW_EMAIL>'"

-------------------------------------------------------------------------------
3. AUTHOR
-------------------------------------------------------------------------------
Andrey Dibrov (andry at inbox dot ru)
