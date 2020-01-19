# python module for commands with extension modules usage: tacklelib, plumbum

tkl_import_module(TACKLELIB_ROOT, 'tacklelib.utils.py', 'tkl')

tkl_source_module(CMDOPLIB_ROOT, 'cmdoplib.std.xsh')
tkl_source_module(CMDOPLIB_ROOT, 'cmdoplib.yaml.xsh')
tkl_source_module(CMDOPLIB_ROOT, 'cmdoplib.csvgit.xsh')
tkl_source_module(CMDOPLIB_ROOT, 'cmdoplib.csvsvn.xsh')
tkl_source_module(CMDOPLIB_ROOT, 'cmdoplib.url.xsh')
tkl_source_module(CMDOPLIB_ROOT, 'cmdoplib.svn.xsh')
tkl_source_module(CMDOPLIB_ROOT, 'cmdoplib.cache.xsh')
tkl_source_module(CMDOPLIB_ROOT, 'cmdoplib.callsvn.xsh')
tkl_source_module(CMDOPLIB_ROOT, 'cmdoplib.callgit.xsh')

import os, sys, io, csv, shlex, copy, re, shutil, math
from conditional import conditional
from datetime import datetime # must be the same everythere
#from datetime import timezone
import tzlocal

discover_executable('GIT_EXEC', 'git', 'GIT')

call_git(['--version'])

def get_git_svn_path_prefix_regex(path):
  # convert all back slashes at first
  git_svn_path_prefix_regex = path.replace('\\', '/')

  # escape all regex characters
  for c in '^$.+[](){}':
    git_svn_path_prefix_regex = git_svn_path_prefix_regex.replace(c, '\\' + c)

  return '^' + git_svn_path_prefix_regex + '(?:/|$)'

def validate_git_refspec(git_local_branch, git_remote_branch):
  if git_local_branch == '.': git_local_branch = ''
  if git_remote_branch == '.': git_remote_branch = ''

  git_svn_branches_startswith = ['git-svn']

  for git_svn_branch_startswith in git_svn_branches_startswith:
    if git_local_branch.startswith(git_svn_branch_startswith):
      raise Exception('git_local_branch value is internally reserved from usage: `' + git_local_branch + '`')
    if git_remote_branch.startswith(git_svn_branch_startswith):
      raise Exception('git_remote_branch value is internally reserved from usage: `' + git_remote_branch + '`')

  if git_local_branch != '' and git_remote_branch == '':
    git_remote_branch = git_local_branch
  elif git_local_branch == '' and git_remote_branch != '':
    git_local_branch = git_remote_branch
  elif git_local_branch == '' and git_remote_branch == '':
    raise Exception('at least one of git_local_branch and git_remote_branch parameters must be a valid branch name')

  return (git_local_branch, git_remote_branch)

def validate_git_svn_refspec(git_svn_remote_branch):
  git_svn_branches_startswith = ['git-svn']

  for git_svn_branch_startswith in git_svn_branches_startswith:
    if not git_svn_remote_branch.startswith(git_svn_branch_startswith):
      raise Exception('git_svn_remote_branch value is not git-svn remote branch: `' + git_svn_remote_branch + '`')

  return git_svn_remote_branch

def get_git_local_refspec_token(git_local_branch, git_remote_branch):
  return 'refs/heads/' + validate_git_refspec(git_local_branch, git_remote_branch)[0]

def get_git_remote_refspec_token(remote_name, git_local_branch, git_remote_branch):
  return 'refs/remotes/' + remote_name + '/' + validate_git_refspec(git_local_branch, git_remote_branch)[1]

def get_git_remote_refspec_token_tuple(remote_name, git_local_branch, git_remote_branch):
  git_local_branch, git_remote_branch = validate_git_refspec(git_local_branch, git_remote_branch)

  return ('refs/remotes/' + remote_name + '/' + git_remote_branch, 'refs/heads/' + git_remote_branch)

def get_git_svn_trunk_remote_refspec_token(remote_name, shorted = False):
  return ('refs/remotes/' if not shorted else '') + remote_name + '/git-svn-trunk'

def get_git_svn_branches_remote_refspec_token(remote_name, shorted = False):
  return ('refs/remotes/' if not shorted else '') + remote_name + '/git-svn-branches'

def get_git_svn_tags_remote_refspec_token(remote_name, shorted = False):
  return ('refs/remotes/' if not shorted else '') + remote_name + '/git-svn-tags'

def get_git_svn_remote_refspec_token(remote_name, git_svn_remote_branch):
  return 'refs/remotes/' + remote_name + '/' + validate_git_svn_refspec(git_svn_remote_branch)

def get_git_fetch_refspec_token(git_local_branch, git_remote_branch):
  git_local_branch, git_remote_branch = validate_git_refspec(git_local_branch, git_remote_branch)

  if git_local_branch == git_remote_branch:
    refspec_token = git_local_branch
  else:
    refspec_token = git_remote_branch + ':refs/heads/' + git_local_branch

  return refspec_token

def get_git_push_refspec_token(git_local_branch, git_remote_branch):
  git_local_branch, git_remote_branch = validate_git_refspec(git_local_branch, git_remote_branch)

  if git_local_branch == git_remote_branch:
    refspec_token = git_local_branch
  else:
    refspec_token = 'refs/heads/' + git_local_branch + ':' + git_remote_branch

  return refspec_token

def get_git_pull_refspec_token(git_local_branch, git_remote_branch):
  git_local_branch, git_remote_branch = validate_git_refspec(git_local_branch, git_remote_branch)

  if git_local_branch == git_remote_branch:
    refspec_token = git_local_branch
  else:
    refspec_token = git_remote_branch + ':refs/heads/' + git_local_branch

  return refspec_token

def git_remove_svn_branch(svn_branch, remote_refspec_token):
  # remove entire branch and the index
  call_git_no_except(['branch', '-D', '-r', svn_branch])
  dir_to_remove = '.git/svn/' + remote_refspec_token
  if os.path.exists(dir_to_remove):
    print('- removing directory: `' + dir_to_remove + '`')
    shutil.rmtree(dir_to_remove)

def get_git_original_refspec_token(refspec_token):
  return 'refs/original/' + refspec_token

def git_remove_svn_original_refspec_token(remote_refspec_token):
  # remove reference
  call_git_no_except(['update-ref', '-d', get_git_original_refspec_token(remote_refspec_token)])

def git_cleanup_local_branch(remote_name, git_local_branch, git_local_refspec_token):
  git_svn_trunk_remote_refspec_token = get_git_svn_trunk_remote_refspec_token(remote_name)

  # recreate the local branch if is on original remote git-svn branch
  git_svn_trunk_original_remote_refspec_token = get_git_original_refspec_token(git_svn_trunk_remote_refspec_token)
  original_git_svn_commit_hash = get_git_remote_head_commit_hash(git_svn_trunk_original_remote_refspec_token, no_except = True)
  if not original_git_svn_commit_hash is None:
    git_local_head_commit_hash = get_git_local_head_commit_hash(git_local_refspec_token, no_except = True)
    if git_local_head_commit_hash == original_git_svn_commit_hash:
      git_recreate_head_branch(git_local_branch)

  git_remove_svn_original_refspec_token(git_svn_trunk_remote_refspec_token)

def git_remove_head_branch(git_local_branch, detach_head = True):
  if detach_head:
    # detach HEAD at first
    call_git_no_except(['checkout', '--detach'])

  # remove branch
  call_git_no_except(['branch', '-D', git_local_branch])

def git_recreate_head_branch(git_local_branch, detach_head = True):
  git_remove_head_branch(git_local_branch, detach_head = detach_head)

  # CAUTION:
  #   The `git switch -c ...` still can guess and create not empty
  #   branch with a commit or commits. Have to use it with the `--orphan` to
  #   supress that behaviour.
  #
  call_git(['switch', '--orphan', git_local_branch])

def git_register_remotes(git_repos_reader, scm_token, remote_name, with_root):
  git_repos_reader.reset()

  if with_root:
    for root_row in git_repos_reader:
      if root_row['scm_token'].strip() == scm_token and root_row['remote_name'].strip() == remote_name:
        root_remote_name = remote_name
        root_git_reporoot = yaml_expand_global_string(root_row['git_reporoot'].strip())

        ret = call_git_no_except(['remote', 'get-url', root_remote_name])
        if not ret[0]:
          call_git(['remote', 'set-url', root_remote_name, root_git_reporoot])
        else:
          git_remote_add_cmdline = root_row['git_remote_add_cmdline'].strip()
          if git_remote_add_cmdline != '.':
            git_remote_add_cmdline = yaml_expand_global_string(git_remote_add_cmdline)
          else:
            git_remote_add_cmdline = ''
          call_git(['remote', 'add', root_remote_name, root_git_reporoot] + shlex.split(git_remote_add_cmdline))
        break

    git_repos_reader.reset()

  for subtree_row in git_repos_reader:
    if subtree_row['scm_token'].strip() == scm_token and subtree_row['parent_remote_name'].strip() == remote_name:
      subtree_remote_name = subtree_row['remote_name'].strip()
      subtree_git_reporoot = yaml_expand_global_string(subtree_row['git_reporoot'].strip())

      ret = call_git_no_except(['remote', 'get-url', subtree_remote_name])
      if not ret[0]:
        call_git(['remote', 'set-url', subtree_remote_name, subtree_git_reporoot])
      else:
        git_remote_add_cmdline = subtree_row['git_remote_add_cmdline'].strip()
        if git_remote_add_cmdline != '.':
          git_remote_add_cmdline = yaml_expand_global_string(git_remote_add_cmdline)
        else:
          git_remote_add_cmdline = ''
        call_git(['remote', 'add', subtree_remote_name, subtree_git_reporoot] + shlex.split(git_remote_add_cmdline))

def git_get_local_branch_refspec_list(regex_match_str = None):
  refspec_list = []

  ret = call_git(['branch', '-l', '--format', '%(refname)'])

  # To iterate over lines instead chars.
  # (see details: https://stackoverflow.com/questions/3054604/iterate-over-the-lines-of-a-string/3054898#3054898 )

  stdout_lines = io.StringIO(ret[1].strip())
  for line in stdout_lines:
    line = line.strip()
    if regex_match_str is None:
      is_matched = True
    else:
      is_matched = True if re.match(regex_match_str, line) else False
    if is_matched:
      refspec_list.append(line)

  return refspec_list if len(refspec_list) > 0 else None

def git_fetch_child_subtree_merge_branches(parent_tuple_ref, children_tuple_ref_list,
                                           git_subtrees_root, svn_repo_root_to_uuid_dict, git_svn_params_dict,
                                           disable_parent_child_ahead_behind_check = False):
  parent_repo_params_ref = parent_tuple_ref[0]
  parent_fetch_state_ref = parent_tuple_ref[1]

  parent_git_local_branch = parent_repo_params_ref['git_local_branch']

  parent_notpushed_svn_commit_list = parent_fetch_state_ref['notpushed_svn_commit_list']
  parent_first_advanced_notpushed_svn_commit = parent_fetch_state_ref['first_advanced_notpushed_svn_commit']

  if len(parent_notpushed_svn_commit_list) > 0:
    parent_first_notpushed_svn_commit_tuple = parent_notpushed_svn_commit_list[0]

    (parent_first_notpushed_svn_commit_rev, parent_first_notpushed_svn_commit_user_name, parent_first_notpushed_svn_commit_timestamp, parent_first_notpushed_svn_commit_date_time) = \
      parent_first_notpushed_svn_commit_tuple
  else:
    parent_first_notpushed_svn_commit_tuple = None

  for child_tuple_ref in children_tuple_ref_list:
    child_repo_params_ref = child_tuple_ref[0]
    child_fetch_state_ref = child_tuple_ref[1]

    subtree_ordinal_index_prefix_str = child_repo_params_ref['ordinal_index_prefix_str']

    subtree_remote_name = child_repo_params_ref['remote_name']

    subtree_git_reporoot = child_repo_params_ref['git_reporoot']
    subtree_svn_reporoot = child_repo_params_ref['svn_reporoot']

    subtree_git_local_branch = child_repo_params_ref['git_local_branch']
    subtree_git_remote_branch = child_repo_params_ref['git_remote_branch']

    subtree_git_path_prefix = child_repo_params_ref['git_path_prefix']
    subtree_svn_path_prefix = child_repo_params_ref['svn_path_prefix']

    subtree_parent_git_path_prefix = child_repo_params_ref['parent_git_path_prefix']
    if subtree_parent_git_path_prefix == '':
      raise Exception('not root branch type must have not empty git parent path prefix')

    subtree_svn_repopath = subtree_svn_reporoot + (('/' + subtree_svn_path_prefix) if subtree_svn_path_prefix != '' else '')

    child_last_pushed_git_svn_commit = child_fetch_state_ref['last_pushed_git_svn_commit']
    child_last_pushed_git_svn_commit_rev = child_last_pushed_git_svn_commit[0]
    child_last_pushed_git_svn_commit_author_timestamp = child_last_pushed_git_svn_commit[2]
    child_last_pushed_git_svn_commit_commit_timestamp = child_last_pushed_git_svn_commit[4]

    subtree_git_wcroot = child_repo_params_ref['git_wcroot']

    # CAUTION:
    #   We can not simply call to `git subtree add ...` here as long as it would immediately make a commit or return `prefix '...' already exists` error.
    #   Instead we must fetch or merge changes into a separate branch and merge them into main branch, for example, like introduced here:
    #   https://stackoverflow.com/questions/17842966/how-can-i-create-a-gitsubtree-of-an-existing-repository/27432237#27432237
    #

    subtree_local_tmp_branch = subtree_remote_name + '--subtree'

    # cleanup through remove entire branch
    call_git_no_except(['branch', '-D', subtree_local_tmp_branch])

    if not child_last_pushed_git_svn_commit_rev > 0:
      continue

    subtree_git_remote_refspec_token, subtree_git_remote_local_refspec_token = \
      get_git_remote_refspec_token_tuple(subtree_remote_name, subtree_git_local_branch, subtree_git_remote_branch)

    # get last pushed commit hash
    #subtree_git_last_pushed_commit_hash = get_git_last_pushed_commit_hash(subtree_git_reporoot, subtree_git_remote_local_refspec_token)
    child_last_pushed_git_svn_commit_tuple = child_fetch_state_ref['last_pushed_git_svn_commit']
    child_last_pushed_git_svn_commit_hash = child_last_pushed_git_svn_commit[1]

    if not child_last_pushed_git_svn_commit_hash is None:
      # Fetch or merge changes either before the first merge commit timestamp from the svn not pushed commits list (including it) or before the entire list end fetch timestamp,
      # otherwise skip a child repostiory merge.
      if not parent_first_notpushed_svn_commit_tuple is None:
        # CAUTION:
        #   We can not use an author timestamp here as long as the git log can only select commits by a commit timestamp, so we have to calculate
        #   a time distance from author timestamp of the last pushed commit to author timestamp of that not pushed commit and add it to commit timestamp
        #   of the last pushed commit as a workaround.
        #
        if not disable_parent_child_ahead_behind_check:
          git_check_if_parent_child_in_ahead_behind_state(parent_tuple_ref, child_tuple_ref = child_tuple_ref)

        until_commit_commit_timestamp = child_last_pushed_git_svn_commit_commit_timestamp + \
          (parent_first_notpushed_svn_commit_timestamp - child_last_pushed_git_svn_commit_author_timestamp)
      else:
        parent_last_notpushed_svn_commit_fetch_end_timestamp = parent_fetch_state_ref['last_notpushed_svn_commit_fetch_end_timestamp']
        until_commit_commit_timestamp = parent_last_notpushed_svn_commit_fetch_end_timestamp

      if not parent_first_advanced_notpushed_svn_commit is None:
        since_commit_commit_timestamp = child_last_pushed_git_svn_commit_commit_timestamp + \
          (parent_first_advanced_notpushed_svn_commit - child_last_pushed_git_svn_commit_author_timestamp)
      else:
        since_commit_commit_timestamp = None

      with local_cwd(' ->> cwd: `{0}`...', ' -<< cwd: `{0}`...', subtree_git_wcroot):
        # find the last svn commit revision when a revision number is not defined
        git_last_svn_rev, child_git_commit_hash, \
        git_commit_author_timestamp, git_commit_author_date_time, \
        git_commit_commit_timestamp, git_commit_commit_date_time, \
        num_overall_git_commits, \
        git_svn_commit_fetch_timestamp = \
          get_last_git_svn_rev_by_git_log(subtree_git_remote_refspec_token,
            subtree_svn_reporoot, subtree_svn_path_prefix, subtree_git_path_prefix,
            git_svn_params_dict,
            until_commit_commit_timestamp = until_commit_commit_timestamp,
            since_commit_commit_timestamp = since_commit_commit_timestamp)

        if git_last_svn_rev > 0:
          advance_svn_notpushed_commits_list(child_tuple_ref, git_last_svn_rev)

        # CAUTION:
        #   Can not use `git fetch` with a particular commit hash becuase of the error message:
        #   `error: Server does not allow request for unadvertised object ...`.
        #

        # cleanup through remove entire branch
        call_git_no_except(['branch', '-D', subtree_local_tmp_branch])

        # create a local branch from a particular commit
        call_git(['branch', '--no-track', subtree_local_tmp_branch, child_git_commit_hash])

      # fetch a local branch from a child working copy into local branch in the parent working copy
      call_git(['fetch', subtree_git_wcroot, 'refs/heads/' + subtree_local_tmp_branch + ':refs/heads/' + subtree_local_tmp_branch])

      """
      if not child_git_commit_hash is None:
        # fetch a particular commit from a child working copy into local branch in the parent working copy
        call_git(['fetch', subtree_git_wcroot, subtree_git_remote_refspec_token + ':refs/heads/' + subtree_local_tmp_branch, child_git_commit_hash])
      """

def git_remove_child_subtree_merge_branches(children_tuple_ref_list):
  for child_tuple_ref in children_tuple_ref_list:
    child_repo_params_ref = child_tuple_ref[0]

    subtree_remote_name = child_repo_params_ref['remote_name']

    subtree_local_tmp_branch = subtree_remote_name + '--subtree'

    call_git_no_except(['branch', '-D', subtree_local_tmp_branch])

# ex: `git checkout -b <git_local_branch> refs/remotes/<remote_name>/<git_remote_branch>`
#
def get_git_switch_branch_args_list(remote_name, git_local_branch, git_remote_branch):
  git_local_branch = validate_git_refspec(git_local_branch, git_remote_branch)[0]
  return ['-c', git_local_branch, get_git_local_refspec_token(git_local_branch, git_remote_branch)]

"""
# ex: `git checkout -b <git_local_branch> refs/remotes/<remote_name>/<git_remote_branch>`
#
def get_git_checkout_branch_args_list(remote_name, git_local_branch, git_remote_branch):
  git_local_branch = validate_git_refspec(git_local_branch, git_remote_branch)[0]
  return ['-b', git_local_branch, get_git_local_refspec_token(git_local_branch, git_remote_branch)]
"""

"""
def get_git_fetch_first_commit_hash(remote_name, git_local_branch, git_remote_branch):
  first_commit_hash = None

  ret = call_git_no_except(['rev-list', '--reverse', '--max-parents=0', 'FETCH_HEAD', get_git_remote_refspec_token(remote_name, git_local_branch, git_remote_branch)])

  # To iterate over lines instead chars.
  # (see details: https://stackoverflow.com/questions/3054604/iterate-over-the-lines-of-a-string/3054898#3054898 )

  for row in io.StringIO(ret[1].strip()):
    first_commit_hash = row.strip()
    break

  return first_commit_hash.strip()
"""

# Returns the first found git commit parameters or nothing.
#
def get_first_git_svn_commit_from_git_log(str):
  commit_svn_rev = 0
  commit_hash = None
  author_timestamp = None
  commit_timestamp = None
  author_date_time = None
  commit_date_time = None

  # To iterate over lines instead chars.
  # (see details: https://stackoverflow.com/questions/3054604/iterate-over-the-lines-of-a-string/3054898#3054898 )

  lines = io.StringIO(str)
  for line in lines:
    value_list = [value.strip() for value in line.split(":", 1)]
    key = value_list[0]
    if key == 'commit':
      commit_hash = value_list[1]
      author_timestamp = None
      commit_timestamp = None
      author_date_time = None
      commit_date_time = None
    elif key == 'timestamp':
      timestamp_list = value_list[1].split('|')
      author_timestamp = int(timestamp_list[0])
      commit_timestamp = int(timestamp_list[1])
    elif key == 'date_time':
      date_time_list = value_list[1].split('|')
      author_date_time = date_time_list[0]
      commit_date_time = date_time_list[1]
    elif key == 'git-svn-id' or key == 'git-svn-to-id':
      param_value = value_list[1]
      git_svn_url_index = param_value.rfind(' ')
      if git_svn_url_index > 0:
        git_svn_url = param_value[:git_svn_url_index].strip()

        commit_svn_rev_index = git_svn_url.rfind('@')
        if commit_svn_rev_index > 0:
          commit_svn_rev_str = git_svn_url[commit_svn_rev_index + 1:]
          commit_svn_rev = int(commit_svn_rev_str)
        elif key == 'git-svn-to-id':
          commit_svn_rev = 0

        return (commit_svn_rev, commit_hash, author_timestamp, author_date_time, commit_timestamp, commit_date_time)

  return (0, None, None, None, None, None)

# Returns the first git commit where was found a git commit hash under the requested remote svn url when an svn commit revision can be taken from next git commit,
# otherwise would return partially the last git commit parameters without svn commit revision and git commit hash.
#
def get_first_or_last_git_svn_commit_from_git_log(str, svn_reporoot, svn_path_prefix, svn_path_exact_match = True, continue_search_svn_rev = False):
  svn_remote_path = svn_reporoot + ('/' + svn_path_prefix if svn_path_prefix != '' else '')

  commit_svn_rev = 0
  commit_hash = None
  author_timestamp = None
  commit_timestamp = None
  author_date_time = None
  commit_date_time = None
  num_commits = 0

  is_commit_located = False
  located_commit_hash = None
  located_author_timestamp = None
  located_commit_timestamp = None
  located_author_date_time = None
  located_commit_date_time = None
  located_num_commits = 0

  num_commits = 0

  # To iterate over lines instead chars.
  # (see details: https://stackoverflow.com/questions/3054604/iterate-over-the-lines-of-a-string/3054898#3054898 )

  lines = io.StringIO(str)
  for line in lines:
    #print(line.strip())
    value_list = [value.strip() for value in line.split(":", 1)]
    key = value_list[0]
    if key == 'commit':
      if is_commit_located:
        if not continue_search_svn_rev or commit_svn_rev > 0:
          # return the previous one
          return (commit_svn_rev,
            located_commit_hash, located_author_timestamp, located_author_date_time, located_commit_timestamp, located_commit_date_time, located_num_commits,
            commit_hash, author_timestamp, author_date_time, commit_timestamp, commit_date_time, num_commits)

      commit_hash = value_list[1]
      author_timestamp = None
      commit_timestamp = None
      author_date_time = None
      commit_date_time = None
      num_commits += 1
    elif key == 'timestamp':
      timestamp_list = value_list[1].split('|')
      author_timestamp = int(timestamp_list[0])
      commit_timestamp = int(timestamp_list[1])
    elif key == 'date_time':
      date_time_list = value_list[1].split('|')
      author_date_time = date_time_list[0]
      commit_date_time = date_time_list[1]
    elif key == 'git-svn-id' or key == 'git-svn-to-id':
      param_value = value_list[1]
      git_svn_url_index = param_value.rfind(' ')
      if git_svn_url_index > 0:
        is_commit_prev_located = is_commit_located

        git_svn_url = param_value[:git_svn_url_index].strip()

        commit_svn_rev_index = git_svn_url.rfind('@')
        if commit_svn_rev_index > 0:
          svn_path = git_svn_url[:commit_svn_rev_index]

          commit_svn_rev_str = git_svn_url[commit_svn_rev_index + 1:]
          commit_svn_rev = int(commit_svn_rev_str)

          svn_path_wo_scheme = tkl.ParseResult('', *tkl.urlparse(svn_path)[1:]).geturl().rstrip('/')
          svn_remote_path_wo_scheme = tkl.ParseResult('', *tkl.urlparse(svn_remote_path)[1:]).geturl().rstrip('/')

          if svn_path_exact_match:
            if svn_path_wo_scheme == svn_remote_path_wo_scheme:
              is_commit_located = True
            else:
              # reset
              commit_svn_rev = 0
          else:
            if (svn_path_wo_scheme + '/').startswith(svn_remote_path_wo_scheme + '/'):
              is_commit_located = True
            else:
              # reset
              commit_svn_rev = 0
        elif key == 'git-svn-to-id':
          svn_path = git_svn_url
          commit_svn_rev = 0

          svn_path_wo_scheme = tkl.ParseResult('', *tkl.urlparse(svn_path)[1:]).geturl().rstrip('/')
          svn_remote_path_wo_scheme = tkl.ParseResult('', *tkl.urlparse(svn_remote_path)[1:]).geturl().rstrip('/')

          if svn_path_exact_match:
            if svn_path_wo_scheme == svn_remote_path_wo_scheme:
              is_commit_located = True
          else:
            if (svn_path_wo_scheme + '/').startswith(svn_remote_path_wo_scheme + '/'):
              is_commit_located = True

        if not is_commit_prev_located and is_commit_located:
          located_commit_hash = commit_hash
          located_author_timestamp = author_timestamp
          located_author_date_time = author_date_time
          located_commit_timestamp = commit_timestamp
          located_commit_date_time = commit_date_time
          located_num_commits = num_commits

  return (commit_svn_rev,
    located_commit_hash, located_author_timestamp, located_author_date_time, located_commit_timestamp, located_commit_date_time, located_num_commits,
    commit_hash, author_timestamp, author_date_time, commit_timestamp, commit_date_time, num_commits)

# Returns the git commit list where was found all svn revisions under the requested remote svn url.
#
def get_git_commit_list_from_git_log(str, svn_reporoot, svn_path_prefix, svn_path_exact_match = True):
  svn_remote_path = svn_reporoot + ('/' + svn_path_prefix if svn_path_prefix != '' else '')

  commit_list = []

  commit_svn_rev = 0
  commit_hash = None
  author_timestamp = None
  commit_timestamp = None
  author_date_time = None
  commit_date_time = None
  num_commits = 0

  # To iterate over lines instead chars.
  # (see details: https://stackoverflow.com/questions/3054604/iterate-over-the-lines-of-a-string/3054898#3054898 )

  lines = io.StringIO(str)
  for line in lines:
    #print(line.strip())
    value_list = [value.strip() for value in line.split(":", 1)]
    key = value_list[0]
    if key == 'commit':
      commit_hash = value_list[1]
      author_timestamp = None
      commit_timestamp = None
      author_date_time = None
      commit_date_time = None
      num_commits += 1
    elif key == 'timestamp':
      timestamp_list = value_list[1].split('|')
      author_timestamp = int(timestamp_list[0])
      commit_timestamp = int(timestamp_list[1])
    elif key == 'date_time':
      date_time_list = value_list[1].split('|')
      author_date_time = date_time_list[0]
      commit_date_time = date_time_list[1]
    elif key == 'git-svn-id' or key == 'git-svn-to-id':
      param_value = value_list[1]
      git_svn_url_index = param_value.rfind(' ')
      if git_svn_url_index > 0:
        git_svn_url = param_value[:git_svn_url_index].strip()

        commit_svn_rev_index = git_svn_url.rfind('@')
        if commit_svn_rev_index > 0:
          svn_path = git_svn_url[:commit_svn_rev_index]

          commit_svn_rev_str = git_svn_url[commit_svn_rev_index + 1:]
          commit_svn_rev = int(commit_svn_rev_str)

          svn_path_wo_scheme = tkl.ParseResult('', *tkl.urlparse(svn_path)[1:]).geturl().rstrip('/')
          svn_remote_path_wo_scheme = tkl.ParseResult('', *tkl.urlparse(svn_remote_path)[1:]).geturl().rstrip('/')

          if svn_path_exact_match:
            if svn_path_wo_scheme == svn_remote_path_wo_scheme:
              commit_list.append((commit_svn_rev, commit_hash, author_timestamp, author_date_time, commit_timestamp, commit_date_time))
          else:
            if (svn_path_wo_scheme + '/').startswith(svn_remote_path_wo_scheme + '/'):
              commit_list.append((commit_svn_rev, commit_hash, author_timestamp, author_date_time, commit_timestamp, commit_date_time))
        elif key == 'git-svn-to-id':
          svn_path = git_svn_url
          commit_svn_rev = 0

          svn_path_wo_scheme = tkl.ParseResult('', *tkl.urlparse(svn_path)[1:]).geturl().rstrip('/')
          svn_remote_path_wo_scheme = tkl.ParseResult('', *tkl.urlparse(svn_remote_path)[1:]).geturl().rstrip('/')

          if svn_path_exact_match:
            if svn_path_wo_scheme == svn_remote_path_wo_scheme:
              commit_list.append((commit_svn_rev, commit_hash, author_timestamp, author_date_time, commit_timestamp, commit_date_time))
          else:
            if (svn_path_wo_scheme + '/').startswith(svn_remote_path_wo_scheme + '/'):
              commit_list.append((commit_svn_rev, commit_hash, author_timestamp, author_date_time, commit_timestamp, commit_date_time))

  return (commit_list if len(commit_list) > 0 else None, num_commits)

def get_git_last_pushed_commit_hash(git_reporoot, git_remote_local_refspec_token):
  git_last_pushed_commit_hash = None

  ret = call_git(['ls-remote', git_reporoot])

  with GitLsRemoteListReader(ret[1].strip()) as git_ls_remote_reader:
    for row in git_ls_remote_reader:
      if row['ref'].strip() == git_remote_local_refspec_token:
        git_last_pushed_commit_hash = row['hash'].strip()
        break

  return git_last_pushed_commit_hash

def get_git_local_head_commit_hash(git_local_refspec_token, no_except = False, verify_ref = True):
  git_local_head_commit_hash = None

  ret = call_git(['show-ref'] + (['--verify'] if verify_ref else []) + [git_local_refspec_token], no_except = no_except)

  with GitShowRefListReader(ret[1].strip()) as git_show_ref_reader:
    for row in git_show_ref_reader:
      if row['ref'].strip() == git_local_refspec_token:
        git_local_head_commit_hash = row['hash'].strip()
        break

  if not git_local_head_commit_hash is None:
    print(git_local_head_commit_hash)

  return git_local_head_commit_hash

def get_git_remote_head_commit_hash(git_remote_refspec_token, no_except = False, verify_ref = True):
  git_remote_head_commit_hash = None

  ret = call_git(['show-ref'] + (['--verify'] if verify_ref else []) + [git_remote_refspec_token], no_except = no_except)

  with GitShowRefListReader(ret[1].strip()) as git_show_ref_reader:
    for row in git_show_ref_reader:
      if row['ref'].strip() == git_remote_refspec_token:
        git_remote_head_commit_hash = row['hash'].strip()
        break

  if not git_remote_head_commit_hash is None:
    print(git_remote_head_commit_hash)

  return git_remote_head_commit_hash

def git_reset_if_head_is_not_last_pushed(git_last_pushed_commit_hash, git_local_refspec_token, git_remote_refspec_token,
                                         verify_head_ref = True, reset_hard = False):
  # compare the last pushed commit hash with the last fetched commit hash and if different, then revert changes

  if not git_last_pushed_commit_hash is None:
    git_remote_head_commit_hash = get_git_remote_head_commit_hash(git_remote_refspec_token)

    if not git_remote_head_commit_hash is None:
      is_fetch_head_commit_last_pushed = True if git_last_pushed_commit_hash == git_remote_head_commit_hash else False
      if not is_fetch_head_commit_last_pushed:
        call_git(['reset'] + (['--hard'] if reset_hard else []) + [git_remote_refspec_token])
        # force reassign the FETCH_HEAD to the last pushed hash
        call_git(['update-ref', git_remote_refspec_token, git_last_pushed_commit_hash])
    else:
      is_fetch_head_commit_last_pushed = False

    # additionally, compare the last pushed commit hash with the head commit hash and if different then revert changes

    git_local_head_commit_hash = get_git_local_head_commit_hash(git_local_refspec_token, no_except = True, verify_ref = verify_head_ref)

    if not git_local_head_commit_hash is None:
      is_head_commit_last_pushed = True if git_last_pushed_commit_hash == git_local_head_commit_hash else False
      if not is_head_commit_last_pushed:
        call_git(['reset'] + (['--hard'] if reset_hard else []) + [git_local_refspec_token])
        # force reassign the HEAD to the last pushed hash
        call_git(['update-ref', git_local_refspec_token, git_last_pushed_commit_hash])
    else:
      is_head_commit_last_pushed = False

    call_git(['show-ref'])
  else:
    call_git_no_except(['show-ref'])

def git_svn_fetch(git_svn_repo_tree_tuple_ref, git_svn_fetch_rev, git_svn_fetch_cmdline_list,
                  last_pruned_git_svn_commit_dict,
                  prune_empty_git_svn_commits, single_rev = False):
  repo_params_ref = git_svn_repo_tree_tuple_ref[0]
  fetch_state_ref = git_svn_repo_tree_tuple_ref[1]

  remote_name = repo_params_ref['remote_name']

  git_local_branch = repo_params_ref['git_local_branch']
  git_remote_branch = repo_params_ref['git_remote_branch']

  last_pushed_git_svn_commit = fetch_state_ref['last_pushed_git_svn_commit']
  last_pushed_git_svn_commit_rev = last_pushed_git_svn_commit[0]

  git_local_refspec_token = get_git_local_refspec_token(git_local_branch, git_remote_branch)
  git_remote_refspec_token, git_remote_local_refspec_token = \
    get_git_remote_refspec_token_tuple(remote_name, git_local_branch, git_remote_branch)

  # cleanup before fetch
  git_cleanup_local_branch(remote_name, git_local_branch, git_local_refspec_token)

  if single_rev:
    call_git(['svn', 'fetch', 'svn', '--localtime', '-r' + str(git_svn_fetch_rev)] + git_svn_fetch_cmdline_list,
      ignore_warnings = False if last_pushed_git_svn_commit_rev > 0 else True)
  else:
    if git_svn_fetch_rev > 1:
      call_git(['svn', 'fetch', 'svn', '--localtime', '-r1:' + str(git_svn_fetch_rev)] + git_svn_fetch_cmdline_list,
        ignore_warnings = False if last_pushed_git_svn_commit_rev > 0 else True,
        max_stdout_lines = 64)
    else:
      call_git(['svn', 'fetch', 'svn', '--localtime', '-r' + str(git_svn_fetch_rev)] + git_svn_fetch_cmdline_list,
        ignore_warnings = False if last_pushed_git_svn_commit_rev > 0 else True)

  if git_svn_fetch_rev > 0:
    git_svn_trunk_remote_refspec_token = get_git_svn_trunk_remote_refspec_token(remote_name)
    git_local_head_commit_hash = get_git_local_head_commit_hash(git_local_refspec_token, no_except = True)
    last_fetched_git_svn_commit_hash = get_git_remote_head_commit_hash(git_svn_trunk_remote_refspec_token, no_except = True)

    if not git_local_head_commit_hash is None:
      # recreate the local branch if is on remote git-svn branch
      if git_local_head_commit_hash == last_fetched_git_svn_commit_hash:
        git_recreate_head_branch(git_local_branch)
        git_local_head_commit_hash = None

    # prune empty git-svn commits
    if prune_empty_git_svn_commits:
      git_prune_empty_git_svn_commits(
        remote_name, git_local_branch,
        git_local_refspec_token, git_remote_refspec_token,
        git_svn_trunk_remote_refspec_token, git_local_head_commit_hash, last_fetched_git_svn_commit_hash,
        last_pruned_git_svn_commit_dict)

def git_prune_empty_git_svn_commits(remote_name, git_local_branch,
                                    git_local_refspec_token, git_remote_refspec_token, git_svn_trunk_remote_refspec_token,
                                    git_local_head_commit_hash, last_fetched_git_svn_commit_hash,
                                    last_pruned_git_svn_commit_dict, reset_hard = True):
  if not git_local_head_commit_hash is None:
    # WORKAROUND:
    #   Sometimes index before the prune is not clean and the prune would fail on that.
    #
    call_git(['reset'] + (['--hard'] if reset_hard else []) + [git_local_refspec_token])
  else:
    # WORKAROUND:
    #   Sometimes index before the switch is not clean and the switch would fail on that
    #   with the error message:
    #   `error: Your local changes to the following files would be overwritten by checkout:`
    #   `Please commit your changes or stash them before you switch branches.`
    #
    call_git(['read-tree', '--empty'])

  if not last_fetched_git_svn_commit_hash is None:
    last_pruned_git_svn_commit_hash = last_pruned_git_svn_commit_dict.get(git_remote_refspec_token)

    # CAUTION:
    #   The `git filter-branch --prune-empty ...` command can fail with the message:
    #   `Found nothing to rewrite` because the `last_pruned_git_svn_commit_hash` can point to the last commit.
    #   We have to check that and avoid the command call.
    #
    if last_pruned_git_svn_commit_hash is None or last_pruned_git_svn_commit_hash != last_fetched_git_svn_commit_hash:
      # CAUTION:
      #   The `git filter-branch --prune-empty ...` command can fail with the message:
      #   `fatal: Needed a single revision` because of not existed HEAD reference.
      #   We have to initialize the HEAD to use the command without the error.
      #
      ret = call_git_no_except(['symbolic-ref', 'HEAD'])
      prev_head_refspec_token = ret[1].strip()
      prev_head_git_commit_hash = get_git_local_head_commit_hash(prev_head_refspec_token, no_except = True)

      if prev_head_git_commit_hash is None:
        # WORKAROUND:
        #   To workaround an issue with the error message
        #   `Ref 'refs/remotes/<remote_name>/git-svn-trunk' was deleted`
        #   `fatal: Not a valid object name HEAD`
        #   we have to temporary assign the local branch to the remote branch.
        #
        call_git(['switch', '--no-guess', '-c', git_local_branch, git_svn_trunk_remote_refspec_token])

      if not last_pruned_git_svn_commit_hash is None:
        call_git(['filter-branch', '--prune-empty', last_pruned_git_svn_commit_hash + '..' + git_svn_trunk_remote_refspec_token],
          env = {'FILTER_BRANCH_SQUELCH_WARNING' : 1})
      else:
        call_git(['filter-branch', '--prune-empty', git_svn_trunk_remote_refspec_token],
          env = {'FILTER_BRANCH_SQUELCH_WARNING' : 1})

      next_pruned_git_svn_commit_hash = get_git_remote_head_commit_hash(git_svn_trunk_remote_refspec_token, no_except = True)

      if prev_head_git_commit_hash is None:
        # switch back onto the main branch (may be not yet born or orphan)
        if not git_local_head_commit_hash is None:
          call_git(['switch', '--no-guess', '-c', git_local_branch, git_local_head_commit_hash])
        else:
          # recreate the local branch
          git_recreate_head_branch(git_local_branch)

      # remove previous remote branch tip backup
      git_remove_svn_original_refspec_token(git_svn_trunk_remote_refspec_token)

      if not prev_head_git_commit_hash is None and prev_head_git_commit_hash != next_pruned_git_svn_commit_hash:
        # CAUTION:
        #   Remove the HEAD backup, but use direct file remove instead of the `git symbolic-ref --delete ...` command,
        #   because of the error message: `fatal: Cannot delete ORIG_HEAD, not a symbolic ref`
        #
        file_to_remove = '.git/ORIG_HEAD'
        if os.path.exists(file_to_remove):
          print('- removing file: `' + file_to_remove + '`')
          os.remove(file_to_remove)
    else:
      next_pruned_git_svn_commit_hash = last_pruned_git_svn_commit_hash

  else:
    last_pruned_git_svn_commit_hash = next_pruned_git_svn_commit_hash = None

  # update dictionary
  if not next_pruned_git_svn_commit_hash is None:
    if last_pruned_git_svn_commit_hash is None or next_pruned_git_svn_commit_hash != last_pruned_git_svn_commit_hash:
      last_pruned_git_svn_commit_dict[git_remote_refspec_token] = next_pruned_git_svn_commit_hash
  elif not last_pruned_git_svn_commit_hash is None:
    del last_pruned_git_svn_commit_hash

def get_git_svn_subtree_ignore_paths_regex_from_repos_reader(git_repos_reader, scm_token, remote_name, svn_reporoot):
  parent_svn_reporoot_urlpath = tkl.ParseResult('', *tkl.urlparse(svn_reporoot)[1:]).geturl()

  collected_subtree_svn_path_prefixes = set()

  git_repos_reader.reset()

  # collects only paths with the same repository root

  for subtree_row in git_repos_reader:
    if subtree_row['scm_token'].strip() == scm_token and subtree_row['parent_remote_name'].strip() == remote_name:
      child_svn_reporoot_urlpath = tkl.ParseResult('', *tkl.urlparse(yaml_expand_global_string(subtree_row['svn_reporoot'].strip()))[1:]).geturl()
      if child_svn_reporoot_urlpath == parent_svn_reporoot_urlpath:
        subtree_svn_path_prefix = subtree_row['svn_path_prefix'].strip()
        if subtree_svn_path_prefix != '.':
          subtree_svn_path_prefix = yaml_expand_global_string(subtree_svn_path_prefix)
          collected_subtree_svn_path_prefixes.add(subtree_svn_path_prefix)

  git_repos_reader.reset()

  # collects the rest paths with different repository roots

  parent_svn_path_prefix = ''
  for subtree_row in git_repos_reader:
    if subtree_row['scm_token'].strip() == scm_token and subtree_row['remote_name'].strip() == remote_name:
      parent_svn_path_prefix = subtree_row['svn_path_prefix'].strip()
      if parent_svn_path_prefix != '.':
        parent_svn_path_prefix = yaml_expand_global_string(parent_svn_path_prefix)
      else:
        parent_svn_path_prefix = ''
      break

  git_repos_reader.reset()

  for subtree_row in git_repos_reader:
    if subtree_row['scm_token'].strip() == scm_token and subtree_row['parent_remote_name'].strip() == remote_name:
      subtree_parent_git_path_prefix = subtree_row['parent_git_path_prefix'].strip()
      if subtree_parent_git_path_prefix != '.':
        subtree_parent_git_path_prefix = yaml_expand_global_string(subtree_parent_git_path_prefix)
      else:
        subtree_parent_git_path_prefix = ''
      if parent_svn_path_prefix != '':
        if subtree_parent_git_path_prefix != '':
          collected_subtree_svn_path_prefixes.add(parent_svn_path_prefix + '/' + subtree_parent_git_path_prefix)
      elif subtree_parent_git_path_prefix != '':
        collected_subtree_svn_path_prefixes.add(subtree_parent_git_path_prefix)

  # generate `--ignore-paths` string from collected paths

  subtree_git_svn_ignore_paths_regex = ''

  for subtree_svn_path_prefix in collected_subtree_svn_path_prefixes:
    subtree_git_svn_path_prefix_regex = get_git_svn_path_prefix_regex(subtree_svn_path_prefix)
    subtree_git_svn_ignore_paths_regex += ('|' if len(subtree_git_svn_ignore_paths_regex) > 0 else '') + subtree_git_svn_path_prefix_regex

  return subtree_git_svn_ignore_paths_regex

def get_git_svn_subtree_ignore_paths_regex_from_parent_ref(parent_tuple_ref, children_tuple_ref_list):
  parent_repo_params_ref = parent_tuple_ref[0]

  parent_svn_reporoot = parent_repo_params_ref['svn_reporoot']

  parent_svn_reporoot_urlpath = tkl.ParseResult('', *tkl.urlparse(parent_svn_reporoot)[1:]).geturl()

  collected_subtree_svn_path_prefixes = set()

  # collects only paths with the same repository root

  for child_tuple_ref in children_tuple_ref_list:
    child_repo_params_ref = child_tuple_ref[0]

    child_svn_reporoot = child_repo_params_ref['svn_reporoot']

    child_svn_reporoot_urlpath = tkl.ParseResult('', *tkl.urlparse(child_svn_reporoot)[1:]).geturl()
    if child_svn_reporoot_urlpath == parent_svn_reporoot_urlpath:
      child_svn_path_prefix = child_repo_params_ref['svn_path_prefix']

      collected_subtree_svn_path_prefixes.add(child_svn_path_prefix)

  # collects the rest paths with different repository roots

  parent_svn_path_prefix = parent_repo_params_ref['svn_path_prefix']

  for child_tuple_ref in children_tuple_ref_list:
    child_repo_params_ref = child_tuple_ref[0]

    child_parent_git_path_prefix = child_repo_params_ref['parent_git_path_prefix']

    collected_subtree_svn_path_prefixes.add(parent_svn_path_prefix + '/' + child_parent_git_path_prefix)

  # generate `--ignore-paths` string from collected paths

  subtree_git_svn_ignore_paths_regex = ''

  for subtree_svn_path_prefix in collected_subtree_svn_path_prefixes:
    subtree_git_svn_path_prefix_regex = get_git_svn_path_prefix_regex(subtree_svn_path_prefix)
    subtree_git_svn_ignore_paths_regex += ('|' if len(subtree_git_svn_ignore_paths_regex) > 0 else '') + subtree_git_svn_path_prefix_regex

  return subtree_git_svn_ignore_paths_regex


def get_default_git_log_root_depth():
  return 16

def get_default_git_log_format():
  return 'commit: %H%ntimestamp: %at|%ct%ndate_time: %ai|%ci%nauthor: %an <%ae>%n%b'

# DESCRIPTION (`get_last_git_svn_rev_by_git_log` + `get_last_git_svn_commit_by_git_log`):
#   The git-svn-id identifier looks like this: `<svn_path> @ <rev> <repo _uuid>`, where <svn_path> is the path in the svn repository that at
#   least points to some root, i.e. which may point to a subdirectory in the svn repository tree.
#   The git-svn commit list can contain mixed git-svn-id identifiers, where the paths in the identifiers can be different and point not only
#   to the root of the svn repository, and therefore, we must start looking for some path and not finding it, we should step by step trim it
#   down one level and search again until the path points to the root. And only after the root path is also not found, we can assume that
#   there is no commit with such a git-svn-id identifier.
#   But, initially we can’t look at the entire list of commits in search of a specific git-svn-id identifier, so we need to set the maximum
#   searching depth, after which we need to truncate the path from the git-svn-id identifier and search the list from the beginning until
#   the desired path and revision will be found in the git-svn-id identifier.
#   We have to make the probability of the appearance of a commit in the list and the depth in the repository tree where the commit will be
#   located dependent.
#   It is obvious that the deeper the commit is located in the tree, the less likely it is to meet in the list, and therefore, you need to
#   look deeper into the list. Thus, we need a formula where the deeper the commit is located in the repository tree, the deeper you need to
#   look for it in the list of commits.
#
#   Such formala is:  `<root_initial_list_depth> + sum(log2(<tree_level>) * <num_elements_on_level_and_above>)` , where
#
#   log2                        - logarithm of base 2 is chosen because logarithm of higher base grows slower.
#   <tree_level>                - number of the tree level beginning from 2, where 2 is the root, so the root element is not
#                                 counting itself and must be associated with the minimal/initial depth of search in the list.
#   <root_initial_list_depth>   - minimal/initial depth of the search in the list for the root element only.
#   <num_elements_on_level_and_above>
#                               - quantity of repositories in the tree on a particular level of the tree plus the all repositories up to the
#                                 root (above the level or with the less level).
#

# returns as tuple:
#   git_last_svn_rev                - last pushed svn revision if has any, CAN BE extracted from the commit with different hash!
#   git_commit_hash                 - the last pushed git-svn commit hash with or without an svn revision
#   git_commit_author_timestamp     - git author timestamp of the `git_commit_hash` commit with or without an svn revision
#   git_commit_author_date_time     - git author datetime of the `git_commit_hash` commit with or without an svn revision
#   git_commit_commit_timestamp     - git commit timestamp of the `git_commit_hash` commit with or without an svn revision
#   git_commit_commit_date_time     - git commit datetime of the `git_commit_hash` commit with or without an svn revision
#   num_overall_git_commits         - number of overall looked up commits from branch HEAD commit by the remote refspec token
#   last_fetch_timestamp            - last fetch timestamp
#
def get_last_git_svn_rev_by_git_log(git_remote_refspec_token, svn_reporoot, svn_path_prefix, git_path_prefix,
                                    git_svn_params_dict,
                                    git_log_depth = -1, git_log_root_depth = get_default_git_log_root_depth(),
                                    git_log_format = get_default_git_log_format(),
                                    until_commit_commit_timestamp = None, since_commit_commit_timestamp = None):
  git_log_prev_depth = -1

  if git_log_depth < 0: # auto calculate
    git_log_depth = git_log_root_depth + git_svn_params_dict['git_log_list_child_max_depth_fetch']
  if not git_log_depth > 0:
    raise Exception('git_log_depth is not positive: value={0}'.format(git_log_depth))

  if not since_commit_commit_timestamp is None and since_commit_commit_timestamp > until_commit_commit_timestamp:
    raise Exception('since_commit_commit_timestamp must less or equal to until_commit_commit_timestamp: since={0} until={0}'.
      format(since_commit_commit_timestamp, until_commit_commit_timestamp))

  num_overall_git_commits = 0

  located_git_commit_hash = None
  located_git_commit_author_timestamp = None
  located_git_commit_author_date_time = None
  located_git_commit_commit_timestamp = None
  located_git_commit_commit_date_time = None

  # 1. iterate to increase the `git log` depth (`--max-count`) in case of equal the first and the last commit timestamps
  # 2. iterate to shift the `git log` window using `--until` parameter
  while True:
    last_fetch_timestamp = datetime.utcnow().timestamp()
    ret = call_git(['log', '--max-count=' + str(git_log_depth), '--format=' + git_log_format,
      git_remote_refspec_token] +
      (['--until', str(until_commit_commit_timestamp)] if not until_commit_commit_timestamp is None else []) +
      (['--since', str(since_commit_commit_timestamp)] if not since_commit_commit_timestamp is None else []) +
      (['--', git_path_prefix] if git_path_prefix != '' else []),
      max_stdout_lines = 16)

    git_last_svn_rev, \
    git_commit_hash, \
    git_commit_author_timestamp, git_commit_author_date_time, \
    git_commit_commit_timestamp, git_commit_commit_date_time, num_git_commits, \
    last_git_commit, \
    last_git_commit_author_timestamp, last_git_commit_author_date_time, \
    last_git_commit_commit_timestamp, last_git_commit_commit_date_time, last_num_git_commits = \
      get_first_or_last_git_svn_commit_from_git_log(ret[1], svn_reporoot, '', svn_path_exact_match = False,
        continue_search_svn_rev = True)

    if located_git_commit_hash is None and not git_commit_hash is None:
      located_git_commit_hash = git_commit_hash
      located_git_commit_author_timestamp = git_commit_author_timestamp
      located_git_commit_author_date_time = git_commit_author_date_time
      located_git_commit_commit_timestamp = git_commit_commit_timestamp
      located_git_commit_commit_date_time = git_commit_commit_date_time

    # found or the `git log` is returned less than requested
    if git_last_svn_rev > 0 or git_log_depth > num_git_commits:
      num_overall_git_commits += num_git_commits - 1
      break

    until_commit_commit_timestamp = last_git_commit_commit_timestamp
    num_overall_git_commits += num_git_commits - 1

    if not since_commit_commit_timestamp is None and since_commit_commit_timestamp > until_commit_commit_timestamp:
      break

  return (git_last_svn_rev, located_git_commit_hash,
    located_git_commit_author_timestamp, located_git_commit_author_date_time, located_git_commit_commit_timestamp, located_git_commit_commit_date_time,
    num_overall_git_commits + 1, last_fetch_timestamp)

# returns as tuple:
#   git_last_svn_rev                - last svn revision if has any, extracts only from the commit with the hash
#   git_commit_hash                 - git commit associated with the last svn revision if has any, otherwise the last git commit
#   git_commin_author_timestamp     - git author timestamp of the `git_commit_hash` commit
#   git_commin_author_date_time     - git author datetime of the `git_commit_hash` commit
#   git_commit_commit_timestamp     - git commit timestamp of the `git_commit_hash` commit
#   git_commit_commit_date_time     - git commit datetime of the `git_commit_hash` commit
#   num_overall_git_commits         - number of overall looked up commits from branch HEAD commit by the remote refspec token
#   last_fetch_timestamp            - last fetch timestamp
#
def get_last_git_svn_commit_by_git_log(git_remote_refspec_token, svn_reporoot, svn_path_prefix, git_path_prefix,
                                       svn_rev, git_svn_params_dict,
                                       git_log_depth = -1, git_log_root_depth = get_default_git_log_root_depth(),
                                       git_log_format = get_default_git_log_format(),
                                       until_commit_commit_timestamp = None, since_commit_commit_timestamp = None):
  git_log_prev_depth = -1

  if git_log_depth < 0: # auto calculate
    git_log_depth = git_log_root_depth + git_svn_params_dict['git_log_list_child_max_depth_fetch']
  if not git_log_depth > 0:
    raise Exception('git_log_depth is not positive: value={0}'.format(git_log_depth))

  if not since_commit_commit_timestamp is None and since_commit_commit_timestamp > until_commit_commit_timestamp:
    raise Exception('since_commit_commit_timestamp must less or equal to until_commit_commit_timestamp: since={0} until={0}'.
      format(since_commit_commit_timestamp, until_commit_commit_timestamp))

  num_overall_git_commits = 0

  # 1. iterate to increase the `git log` depth (`--max-count`) in case of equal the first and the last commit timestamps
  # 2. iterate to shift the `git log` window using `--until` parameter
  while True:
    last_fetch_timestamp = datetime.utcnow().timestamp()
    ret = call_git(['log', '--max-count=' + str(git_log_depth), '--format=' + git_log_format,
      git_remote_refspec_token] +
      (['--until', str(until_commit_commit_timestamp)] if not until_commit_commit_timestamp is None else []) +
      (['--since', str(since_commit_commit_timestamp)] if not since_commit_commit_timestamp is None else []) +
      (['--', git_path_prefix] if git_path_prefix != '' else []),
      max_stdout_lines = 16)

    git_svn_commit_list, num_git_commits = \
      get_git_commit_list_from_git_log(ret[1], svn_reporoot, '', svn_path_exact_match = False)

    # return if svn revision is found
    if not git_svn_commit_list is None:
      commit_index = 0

      for git_svn_commit in git_svn_commit_list:
        git_svn_commit_rev = git_svn_commit[0]
        if git_svn_commit_rev == svn_rev:
          return (*git_svn_commit, num_overall_git_commits + commit_index, last_fetch_timestamp)
        elif git_svn_commit_rev < svn_rev:
          # if found revision is less than searching one, then return as not found
          return (0, None, None, None, None, None, num_overall_git_commits + commit_index, last_fetch_timestamp)

        commit_index += 1

      last_git_commit_commit_timestamp = git_svn_commit_list[-1][4] # a last commit commit timestamp

    # the `git log` is returned less than requested
    if git_svn_commit_list is None or git_log_depth > num_git_commits:
      num_overall_git_commits += num_git_commits - 1
      break

    until_commit_commit_timestamp = last_git_commit_commit_timestamp
    num_overall_git_commits += num_git_commits - 1

    if not since_commit_commit_timestamp is None and since_commit_commit_timestamp > until_commit_commit_timestamp:
      break

  return (0, None, None, None, None, None, num_overall_git_commits + 1, last_fetch_timestamp)

def git_update_svn_config_refspecs(remote_name):
  ret = call_git_no_except(['config', 'svn-remote.svn.fetch'])
  if not ret[0]:
    svn_remote_fetch_refspec_token = ret[1].strip()
    if len(svn_remote_fetch_refspec_token) > 0:
      svn_remote_fetch_refspec_token = svn_remote_fetch_refspec_token.replace('refs/remotes/origin/trunk', get_git_svn_trunk_remote_refspec_token(remote_name))
      call_git(['config', 'svn-remote.svn.fetch', svn_remote_fetch_refspec_token])

  ret = call_git_no_except(['config', 'svn-remote.svn.branches'])
  if not ret[0]:
    svn_remote_branches_refspec_token = ret[1].strip()
    if len(svn_remote_branches_refspec_token) > 0:
      svn_remote_branches_refspec_token = svn_remote_branches_refspec_token.replace('refs/remotes/origin/*', get_git_svn_branches_remote_refspec_token(remote_name) + '/*')
      call_git(['config', 'svn-remote.svn.branches', svn_remote_branches_refspec_token])

  ret = call_git_no_except(['config', 'svn-remote.svn.tags'])
  if not ret[0]:
    svn_remote_tags_refspec_token = ret[1].strip()
    if len(svn_remote_tags_refspec_token) > 0:
      svn_remote_tags_refspec_token = svn_remote_tags_refspec_token.replace('refs/remotes/origin/tags/*', get_git_svn_tags_remote_refspec_token(remote_name) + '/*')
      call_git(['config', 'svn-remote.svn.tags', svn_remote_tags_refspec_token])

def get_git_subtree_wcroot(dir_prefix_str, git_subtrees_root, subtree_remote_name, subtree_parent_git_path_prefix):
  return os.path.abspath(os.path.join(git_subtrees_root, dir_prefix_str + subtree_remote_name + "'" + subtree_parent_git_path_prefix.replace('/', '--'))).replace('\\', '/')

def git_init(configure_dir, scm_token, git_subtrees_root = None, root_only = False, update_svn_repo_uuid = False, verbosity = 0):
  print("git_init: {0}".format(configure_dir))

  set_verbosity_level(verbosity)

  if configure_dir == '':
    print_err("{0}: error: configure directory is not defined.".format(sys.argv[0]))
    return 1

  if configure_dir[-1:] in ['\\', '/']:
    configure_dir = configure_dir[:-1]

  if not os.path.isdir(configure_dir):
    print_err("{0}: error: configure directory does not exist: `{1}`.".format(sys.argv[0], configure_dir))
    return 32

  if not git_subtrees_root is None and not os.path.isdir(git_subtrees_root):
    print_err("{0}: error: git subtrees root directory does not exist: git_subtrees_root=`{1}`.".format(sys.argv[0], git_subtrees_root))
    return 33

  wcroot_dir = getglobalvar(scm_token + '.WCROOT_DIR')
  if wcroot_dir == '': return -254
  if WCROOT_OFFSET == '': return -253

  wcroot_path = os.path.abspath(os.path.join(WCROOT_OFFSET, wcroot_dir)).replace('\\', '/')

  git_user = getglobalvar(scm_token + '.USER')
  git_email = getglobalvar(scm_token + '.EMAIL')

  git_svn_preserve_empty_dirs = getglobalvar(scm_token + '.GIT_SVN_REMOTE.PRESERVE_EMPTY_DIRS')
  if git_svn_preserve_empty_dirs is None:
    git_svn_preserve_empty_dirs = getglobalvar('GIT_SVN_REMOTE.PRESERVE_EMPTY_DIRS')

  git_svn_preserve_empty_dirs_file_placeholder = getglobalvar(scm_token + '.GIT_SVN_REMOTE.PRESERVE_EMPTY_DIRS_FILE_PLACEHOLDER')
  if git_svn_preserve_empty_dirs_file_placeholder is None:
    git_svn_preserve_empty_dirs_file_placeholder = getglobalvar('GIT_SVN_REMOTE.PRESERVE_EMPTY_DIRS_FILE_PLACEHOLDER')

  if not os.path.exists(wcroot_path):
    os.mkdir(wcroot_path)

  with local_cwd(' ->> cwd: `{0}`...', ' -<< cwd: `{0}`...', wcroot_path), \
       GitReposListReader(configure_dir + '/git_repos.lst') as git_repos_reader, ServiceProcCache() as svc_proc_cache:
    executed_procs = cache_init_service_proc(svc_proc_cache)

    with tkl.OnExit(lambda: cache_close_running_procs(executed_procs, svc_proc_cache)):
      column_names, column_widths = get_git_svn_repos_list_table_params()

      is_builtin_git_subtrees_root = False
      if git_subtrees_root is None:
        git_subtrees_root = wcroot_path + '/.git/.pyxvcs/gitwc'
        is_builtin_git_subtrees_root = True

      git_svn_repo_tree_dict, git_svn_repo_tree_tuple_ref_preorder_list, svn_repo_root_to_uuid_dict, git_svn_params_dict = \
        read_git_svn_repo_list(git_repos_reader, scm_token, wcroot_path, git_subtrees_root, column_names, column_widths,
          update_svn_repo_uuid = update_svn_repo_uuid)

      if not os.path.exists(wcroot_path + '/.git'):
        call_git(['init', wcroot_path])

      root_remote_name = None
      remote_name_list = []

      git_repos_reader.reset()

      for row in git_repos_reader:
        if row['scm_token'].strip() == scm_token and row['branch_type'].strip() == 'root':
          root_remote_name = row['remote_name'].strip()
          remote_name_list.append(root_remote_name)

          root_svn_reporoot = yaml_expand_global_string(row['svn_reporoot'].strip())

          root_parent_git_path_prefix = row['parent_git_path_prefix'].strip()
          if root_parent_git_path_prefix != '.':
            root_parent_git_path_prefix = yaml_expand_global_string(root_parent_git_path_prefix)
          else:
            root_parent_git_path_prefix = ''
          if root_parent_git_path_prefix != '':
            raise Exception('parent_git_path_prefix must be empty for the root repository: parent_git_path_prefix=`{0}`'.format(root_parent_git_path_prefix))

          root_git_path_prefix = row['git_path_prefix'].strip()
          if root_git_path_prefix != '.':
            root_git_path_prefix = yaml_expand_global_string(root_git_path_prefix)
          else:
            root_git_path_prefix = ''
          if root_git_path_prefix != '':
            raise Exception('root_git_path_prefix must be empty for the root repository: git_path_prefix=`{0}`'.format(root_git_path_prefix))

          root_svn_path_prefix = row['svn_path_prefix'].strip()
          if root_svn_path_prefix != '.':
            root_svn_path_prefix = yaml_expand_global_string(row['svn_path_prefix'].strip())
          else:
            root_svn_path_prefix = ''

          root_git_svn_init_cmdline = row['git_svn_init_cmdline'].strip()
          if root_git_svn_init_cmdline != '.':
            root_git_svn_init_cmdline = yaml_expand_global_string(root_git_svn_init_cmdline)
          else:
            root_git_svn_init_cmdline = ''

          break

      if root_remote_name is None:
        raise Exception('the root record is not found in the git repositories list: scm_token={0}'.format(scm_token))

      root_git_svn_init_cmdline_list = shlex.split(root_git_svn_init_cmdline)

      # Always use the trunk, even if it is in a subdirectory, to later be able to use the SVN url always as a root url without relative suffix and
      # let the git to generate a commit hash based on a complete path from the SVN root.
      if '--stdlayout' not in root_git_svn_init_cmdline_list and '--trunk' not in root_git_svn_init_cmdline_list:
        if root_svn_path_prefix == '':
          raise Exception('svn_path_prefix parameter must not be empty: scm_token={0} remote_name={1}'.format(scm_token, root_remote_name))
        root_git_svn_init_cmdline_list.append('--trunk=' + root_svn_path_prefix)
      root_svn_url = root_svn_reporoot

      # generate `--ignore_paths` from child repositories

      git_svn_init_ignore_paths_regex = \
        get_git_svn_subtree_ignore_paths_regex_from_repos_reader(git_repos_reader, scm_token, root_remote_name, root_svn_reporoot)
      if len(git_svn_init_ignore_paths_regex) > 0:
        root_git_svn_init_cmdline_list.append('--ignore-paths=' + git_svn_init_ignore_paths_regex)

      # (re)init root git svn
      is_git_root_wcroot_exists = os.path.exists(wcroot_path + '/.git/svn')
      if is_git_root_wcroot_exists:
        ret = call_git_no_except(['config', 'svn-remote.svn.url'])

      # Reinit if:
      #   1. git/svn wcroot is not found or
      #   2. svn remote url is not registered or
      #   3. svn remote url is different
      #
      if is_git_root_wcroot_exists and not ret[0]:
        root_svn_url_reg = ret[1].strip()
      if not is_git_root_wcroot_exists or ret[0] or root_svn_url_reg != root_svn_url:
        # removing the git svn config section to avoid it's records duplication on reinit
        call_git_no_except(['config', '--remove-section', 'svn-remote.svn'])

        if SVN_SSH_ENABLED:
          root_svn_url_to_init = tkl.make_url(root_svn_url, yaml_expand_global_string('${${SCM_TOKEN}.SVNSSH.USER}',
            search_by_pred_at_third = lambda var_name: getglobalvar(var_name)))
        else:
          root_svn_url_to_init = root_svn_url

        call_git(['svn', 'init', root_svn_url_to_init] + root_git_svn_init_cmdline_list)

      # update refspec of git-svn branch to avoid an intersection
      git_update_svn_config_refspecs(root_remote_name)

      call_git(['config', 'user.name', git_user])
      call_git(['config', 'user.email', git_email])

      # preserve empty directories
      if not git_svn_preserve_empty_dirs is None:
        if git_svn_preserve_empty_dirs:
          call_git(['config', 'svn-remote.svn.preserve-empty-dirs', 'true'])
        else:
          call_git(['config', 'svn-remote.svn.preserve-empty-dirs', 'false'])

      if not git_svn_preserve_empty_dirs_file_placeholder is None:
        call_git(['config', 'svn-remote.svn.placeholder-filename', git_svn_preserve_empty_dirs_file_placeholder])

      # register git remotes
      git_register_remotes(git_repos_reader, scm_token, root_remote_name, True)

      print('---')

      if root_only:
        return

      # Initialize non root git repositories as stanalone working copies inside the `git_subtrees_root` directory,
      # use the combination of the `remote_name` and the `parent_git_path_prefix` as a prefix to a working copy directory.

      git_repos_reader.reset()

      for subtree_row in git_repos_reader:
        if subtree_row['scm_token'].strip() == scm_token and subtree_row['branch_type'].strip() != 'root':
          subtree_remote_name = subtree_row['remote_name'].strip()
          if subtree_remote_name in remote_name_list:
            raise Exception('remote_name must be unique in the repositories list for the same scm_token: remote_name=`{0}` scm_token=`{1}`'.
              format(subtree_remote_name, scm_token))

          subtree_parent_remote_name = subtree_row['parent_remote_name'].strip()
          if subtree_parent_remote_name not in remote_name_list:
            raise Exception('parent_remote_name must be declared as a remote name for the same scm_token: parent_remote_name=`{0}` scm_token=`{1}`'.
              format(subtree_parent_remote_name, scm_token))

          remote_name_list.append(subtree_remote_name)

          subtree_svn_reporoot = yaml_expand_global_string(subtree_row['svn_reporoot'].strip())

          subtree_parent_git_path_prefix = subtree_row['parent_git_path_prefix'].strip()
          if subtree_parent_git_path_prefix != '.':
            subtree_parent_git_path_prefix = yaml_expand_global_string(subtree_parent_git_path_prefix)
          else:
            subtree_parent_git_path_prefix = ''
          if subtree_parent_git_path_prefix == '':
            raise Exception('parent_git_path_prefix must be not empty for the not root repository')

          subtree_svn_path_prefix = subtree_row['svn_path_prefix'].strip()
          if subtree_svn_path_prefix != '.':
            subtree_svn_path_prefix = yaml_expand_global_string(subtree_svn_path_prefix)
          else:
            subtree_svn_path_prefix = ''

          subtree_git_svn_init_cmdline = subtree_row['git_svn_init_cmdline'].strip()
          if subtree_git_svn_init_cmdline != '.':
            subtree_git_svn_init_cmdline = yaml_expand_global_string(subtree_git_svn_init_cmdline)
          else:
            subtree_git_svn_init_cmdline = ''

          subtree_git_wcroot = None
          for git_svn_repo_tree_tuple_ref in git_svn_repo_tree_tuple_ref_preorder_list:
            repo_params_ref = git_svn_repo_tree_tuple_ref[0]
            if repo_params_ref['remote_name'] == subtree_remote_name:
              subtree_git_wcroot = repo_params_ref['git_wcroot']
              break

          if is_builtin_git_subtrees_root:
            if not os.path.exists(git_subtrees_root):
              print('>mkdir: -p ' + git_subtrees_root)
              try:
                os.makedirs(git_subtrees_root)
              except FileExistsError:
                pass

          if not os.path.exists(subtree_git_wcroot):
            print('>mkdir: ' + subtree_git_wcroot)
            try:
              os.mkdir(subtree_git_wcroot)
            except FileExistsError:
              pass

          with local_cwd(' ->> cwd: `{0}`...', ' -<< cwd: `{0}`...', subtree_git_wcroot):
            if not os.path.exists(subtree_git_wcroot + '/.git'):
              call_git(['init', subtree_git_wcroot])

            subtree_git_svn_init_cmdline_list = shlex.split(subtree_git_svn_init_cmdline)

            # Always use the trunk, even if it is in a subdirectory, to later be able to use the SVN url always as a root url without relative suffix and
            # let the git to generate a commit hash based on a complete path from the SVN root.
            if '--stdlayout' not in subtree_git_svn_init_cmdline_list and '--trunk' not in subtree_git_svn_init_cmdline_list:
              if subtree_svn_path_prefix == '':
                raise Exception('svn_path_prefix parameter must not be empty: scm_token={0} remote_name={1}'.format(scm_token, subtree_remote_name))
              subtree_git_svn_init_cmdline_list.append('--trunk=' + subtree_svn_path_prefix)
            subtree_svn_url = subtree_svn_reporoot

            with GitReposListReader(configure_dir + '/git_repos.lst') as subtree_git_repos_reader:
              # generate `--ignore_paths` from child repositories

              subtree_git_svn_init_ignore_paths_regex = \
                get_git_svn_subtree_ignore_paths_regex_from_repos_reader(subtree_git_repos_reader, scm_token, subtree_remote_name, subtree_svn_reporoot)
              if len(subtree_git_svn_init_ignore_paths_regex) > 0:
                subtree_git_svn_init_cmdline_list.append('--ignore-paths=' + subtree_git_svn_init_ignore_paths_regex)

              # (re)init subtree git svn
              is_git_subtree_wcroot_exists = os.path.exists(subtree_git_wcroot + '/.git/svn')
              if is_git_subtree_wcroot_exists:
                ret = call_git_no_except(['config', 'svn-remote.svn.url'])

              # Reinit if:
              #   1. git/svn wcroot is not found or
              #   2. svn remote url is not registered or
              #   3. svn remote url is different
              #
              if is_git_subtree_wcroot_exists and not ret[0]:
                subtree_svn_url_reg = ret[1].strip()
              if not is_git_subtree_wcroot_exists or ret[0] or subtree_svn_url_reg != subtree_svn_url:
                # removing the git svn config section to avoid it's records duplication on reinit
                call_git_no_except(['config', '--remove-section', 'svn-remote.svn'])

                if SVN_SSH_ENABLED:
                  subtree_svn_url_to_init = tkl.make_url(subtree_svn_url, yaml_expand_global_string('${${SCM_TOKEN}.SVNSSH.USER}',
                    search_by_pred_at_third = lambda var_name: getglobalvar(var_name)))
                else:
                  subtree_svn_url_to_init = subtree_svn_url

                call_git(['svn', 'init', subtree_svn_url_to_init] + subtree_git_svn_init_cmdline_list)

              # update refspec of git-svn branch to avoid an intersection
              git_update_svn_config_refspecs(subtree_remote_name)

              call_git(['config', 'user.name', git_user])
              call_git(['config', 'user.email', git_email])

              # preserve empty directories
              if not git_svn_preserve_empty_dirs is None:
                if git_svn_preserve_empty_dirs:
                  call_git(['config', 'svn-remote.svn.preserve-empty-dirs', 'true'])
                else:
                  call_git(['config', 'svn-remote.svn.preserve-empty-dirs', 'false'])

              if not git_svn_preserve_empty_dirs_file_placeholder is None:
                call_git(['config', 'svn-remote.svn.placeholder-filename', git_svn_preserve_empty_dirs_file_placeholder])

              # register git remotes
              git_register_remotes(subtree_git_repos_reader, scm_token, subtree_remote_name, True)

          print('---')

def git_print_repos_list_header(column_names, column_widths, fmt_str = '{:<{}} {:<{}} {:<{}} {:<{}} {:<{}} {:<{}}'):
  print('  ' + fmt_str.format(
    *(i for j in [(column_name, column_width) for column_name, column_width in zip(column_names, column_widths)] for i in j)
  ))

  text = ''
  for column_width in column_widths:
    if len(text) > 0:
      text += r' '
    text += (column_width * '=')

  print('  ' + text)

def git_print_repos_list_row(row_values, column_widths, fmt_str = '{:<{}} {:<{}} {:<{}} {:<{}} {:<{}} {:<{}}'):
  print('  ' + fmt_str.format(
    *(i for j in [(row_value, column_width) for row_value, column_width in zip(row_values, column_widths)] for i in j)
  ))

def git_print_repos_list_footer(column_widths):
  text = ''
  for column_width in column_widths:
    if len(text) > 0:
      text += r' '
    text += (column_width * '-')

  print('  ' + text)

def read_git_svn_repo_list(git_repos_reader, scm_token, wcroot_path, git_subtrees_root, column_names, column_widths, update_svn_repo_uuid = True):
  print('- Reading GIT-SVN repositories list:')

  git_repos_reader.reset()

  root_remote_name = None

  for row in git_repos_reader:
    if row['scm_token'].strip() == scm_token and row['branch_type'].strip() == 'root':
      root_remote_name = row['remote_name'].strip()

      root_git_reporoot = yaml_expand_global_string(row['git_reporoot'].strip())
      root_svn_reporoot = yaml_expand_global_string(row['svn_reporoot'].strip())

      root_parent_git_path_prefix = row['parent_git_path_prefix'].strip()
      if root_parent_git_path_prefix != '.':
        root_parent_git_path_prefix = yaml_expand_global_string(root_parent_git_path_prefix)
      else:
        root_parent_git_path_prefix = ''
      if root_parent_git_path_prefix != '':
        raise Exception('parent_git_path_prefix must be empty for the root repository: parent_git_path_prefix=`{0}`'.format(root_parent_git_path_prefix))

      root_git_path_prefix = row['git_path_prefix'].strip()
      if root_git_path_prefix != '.':
        root_git_path_prefix = yaml_expand_global_string(root_git_path_prefix)
      else:
        root_git_path_prefix = ''
      if root_git_path_prefix != '':
        raise Exception('git_path_prefix must be empty for the root repository: git_path_prefix=`{0}`'.format(root_git_path_prefix))

      root_svn_path_prefix = row['svn_path_prefix'].strip()
      if root_svn_path_prefix != '.':
        root_svn_path_prefix = yaml_expand_global_string(root_svn_path_prefix)
      else:
        root_svn_path_prefix = ''

      root_git_local_branch = yaml_expand_global_string(row['git_local_branch'].strip())
      root_git_remote_branch = yaml_expand_global_string(row['git_remote_branch'].strip())

      break

  if root_remote_name is None:
    raise Exception('the root record is not found in the git repositories list: scm_token={0}'.format(scm_token))

  if git_subtrees_root is None:
    git_subtrees_root = wcroot_path + '/.git/.pyxvcs/gitwc'

  root_svn_repopath = root_svn_reporoot + (('/' + root_svn_path_prefix) if root_svn_path_prefix != '' else '')

  git_print_repos_list_header(column_names, column_widths)

  row_values = [root_remote_name, root_git_reporoot, root_parent_git_path_prefix, root_svn_repopath, root_git_local_branch, root_git_remote_branch]
  git_print_repos_list_row(row_values, column_widths)

  # Recursive format:
  #   { <parent_repo_remote_name> : ( <parent_repo_params>, <parent_fetch_state>, { <child_remote_name> : ( <child_repo_params>, <child_fetch_state>, ... ), ... } ) }
  #   , where:
  #
  #   <*_repo_params>:  {
  #     'ordinal_index'                                   : <integer>,
  #     'ordinal_index_prefix_str'                        : <string>,
  #     'nest_index'                                      : <integer>,
  #     'parent_tuple_ref'                                : <tuple>,
  #     'children_tuple_ref_list'                         : [<tuple>, ...],
  #     'num_on_level_and_above'                          : <integer>,
  #     'num_on_level'                                    : <integer>,
  #     'remote_name'                                     : <string>,
  #     'parent_remote_name'                              : <string>,
  #     'git_reporoot'                                    : <string>,
  #     'parent_git_path_prefix'                          : <string>,
  #     'svn_reporoot'                                    : <string>,
  #     'git_path_prefix'                                 : <string>,
  #     'svn_path_prefix'                                 : <string>,
  #     'svn_repo_uuid'                                   : <string>,
  #     'git_local_branch'                                : <string>,
  #     'git_remote_branch'                               : <string>,
  #     'git_wcroot'                                      : <string>
  #   }
  #
  #   <*_fetch_state>:  {
  #     # True if can not push into related GIT repository (applicable to a leaf repository ONLY)
  #     'is_read_only_repo'                               : <boolean>,
  #
  #     # It is required to interrupt the entire iteration on that, otherwise the race condition can take a place, because we have to request
  #     # the last not pushed svn commit twice to properly detect changes and avoid the race condition.
  #     #
  #     'min_tree_time_of_last_notpushed_svn_commit'      : (<timestamp>, <datetime>, <repo_ref>),  # can be a None if have has no not pushed SVN commits
  #
  #     # Has meaning only if a subtree has a read only leaf repository and not pushed commits in it.
  #     # In that case we can make a push only before that commit timestamp, otherwise the read
  #     # only repository must be synchronized some there else to continue with a subtree repositories.
  #     #
  #     'min_ro_tree_time_of_first_notpushed_svn_commit'  : (<timestamp>, <datetime>, <repo_ref>),  # can be a None if have has no not pushed SVN commits
  #                                                                                                 # in a read only leaf repository or does not have read only
  #                                                                                                 # leaf repository in a subtree
  #
  #     'last_pruned_git_svn_commit_dict'                 : {<refspec_token> : <git_hash>, ...}
  #
  #     'last_pushed_git_svn_commit'                      : (<svn_rev>, <git_hash>, <author_timestamp>, <author_date_time>, <commit_timestamp>, <commit_date_time>),
  #     'last_pushed_git_svn_commit_fetch_timestamp'      : <integer>,                              # latest timestamp before the last pushed git-svn commit has been fetched
  #
  #     'notpushed_svn_commit_list'                       : [
  #       (<svn_rev>, <svn_user_name>, <svn_timestamp>, <svn_date_time>),
  #     ],
  #     'first_advanced_notpushed_svn_commit'             : (<svn_rev>, <svn_user_name>, <svn_timestamp>, <svn_date_time>),
  #     'last_notpushed_svn_commit_fetch_end_timestamp'   : <integer>,
  #
  #     'is_first_time_push'                              : <boolean>
  #   }
  #
  git_svn_repo_tree_dict = {
    root_remote_name : (
      {
        'ordinal_index'                 : 0,
        'ordinal_index_prefix_str'      : '',
        'nest_index'                    : 0,                  # the root
        'parent_tuple_ref'              : None,
        'children_tuple_ref_list'       : [],                 # empty list if have has no children
        'num_on_level_and_above'        : 1,                  # the root only
        'num_on_level'                  : 1,                  # the root only
        'remote_name'                   : root_remote_name,
        'parent_remote_name'            : '.',                # special case: if parent remote name is the '.', then it is the root
        'git_reporoot'                  : root_git_reporoot,
        'parent_git_path_prefix'        : root_parent_git_path_prefix,
        'svn_reporoot'                  : root_svn_reporoot,
        'svn_repo_uuid'                 : '',                 # to avoid complex compare
        'git_path_prefix'               : root_git_path_prefix,
        'svn_path_prefix'               : root_svn_path_prefix,
        'git_local_branch'              : root_git_local_branch,
        'git_remote_branch'             : root_git_remote_branch,
        'git_wcroot'                    : '.',
        'git_ignore_paths_regex'        : ''
      },
      # must be assigned at once, otherwise: `TypeError: 'tuple' object does not support item assignment`
      {},
      {}
    )
  }

  git_svn_repo_tree_tuple_ref_preorder_list = [ git_svn_repo_tree_dict[root_remote_name] ]

  # Format: [ <ref_to_repo_tree_tuple>, ... ]
  #
  parent_child_remote_names_to_parse = [ git_svn_repo_tree_dict[root_remote_name] ]

  git_svn_params_dict = {
    'git_log_list_child_max_depth_fetch' : None # excluding the tree root, will be initialized based on input parameters and on the tree structure depth
  }

  git_log_list_child_max_depth_fetch = 0

  # To accumulate number of elements on a tree level and propagate quantity of them to all parents on the list reset
  # (for the next level store or after the end of the loop).
  num_elems_per_level = []  # the root is excluded
  last_parent_refs_on_prev_level_to_update = []
  last_parent_refs_on_next_level_to_update = []
  last_num_children_on_prev_level = 0
  last_num_children_on_next_level = 0
  last_parent_nest_index = 0

  ordinal_index = 1

  # repository tree pre-order traversal 
  while True: # read `parent_child_remote_names_to_parse` until empty
    parent_tuple_ref = parent_child_remote_names_to_parse.pop(0)
    parent_repo_params = parent_tuple_ref[0]
    parent_nest_index = parent_repo_params['nest_index']
    parent_remote_name = parent_repo_params['remote_name']
    parent_parent_remote_name = parent_repo_params['parent_remote_name']

    # reset the list if parent nest level is changed, this is because the nest level should only increase
    if parent_nest_index != last_parent_nest_index:
      for parent_ref_to_update in last_parent_refs_on_prev_level_to_update:
        parent_repo_params_to_update = parent_ref_to_update[0]

        parent_parent_repo_tuple_ref = parent_repo_params_to_update['parent_tuple_ref']
        parent_parent_repo_params = parent_parent_repo_tuple_ref[0] if not parent_parent_repo_tuple_ref is None else None

        parent_parent_num_on_level_and_above = parent_parent_repo_params['num_on_level_and_above'] if not parent_parent_repo_params is None else 1 # 1 - the root only

        parent_repo_params_to_update['num_on_level_and_above'] = parent_parent_num_on_level_and_above + last_num_children_on_prev_level
        parent_repo_params_to_update['num_on_level'] = last_num_children_on_prev_level

      if last_num_children_on_prev_level > 0:
        # save elements from previous level
        num_elems_per_level.append(last_num_children_on_prev_level)

      # reset
      last_parent_refs_on_prev_level_to_update = last_parent_refs_on_next_level_to_update
      last_parent_refs_on_next_level_to_update = []
      last_num_children_on_prev_level = last_num_children_on_next_level
      last_num_children_on_next_level = 0
      last_parent_nest_index = parent_nest_index

    remote_name_list = [parent_remote_name]

    insert_to_front_index = 0

    git_repos_reader.reset()

    for subtree_row in git_repos_reader:
      if subtree_row['scm_token'].strip() == scm_token and subtree_row['branch_type'].strip() != 'root':
        subtree_parent_remote_name = subtree_row['parent_remote_name'].strip()

        if subtree_parent_remote_name == parent_remote_name:
          last_num_children_on_next_level += 1

          subtree_remote_name = subtree_row['remote_name'].strip()
          subtree_git_reporoot = yaml_expand_global_string(subtree_row['git_reporoot'].strip())
          subtree_svn_reporoot = yaml_expand_global_string(subtree_row['svn_reporoot'].strip())
          subtree_git_local_branch = yaml_expand_global_string(subtree_row['git_local_branch'].strip())
          subtree_git_remote_branch = yaml_expand_global_string(subtree_row['git_remote_branch'].strip())

          subtree_parent_git_path_prefix = subtree_row['parent_git_path_prefix'].strip()
          if subtree_parent_git_path_prefix != '.':
            subtree_parent_git_path_prefix = yaml_expand_global_string(subtree_parent_git_path_prefix)
          else:
            subtree_parent_git_path_prefix = ''
          if subtree_parent_git_path_prefix == '':
            raise Exception('not root branch type must have not empty git subtree path prefix')

          subtree_git_path_prefix = subtree_row['git_path_prefix'].strip()
          if subtree_git_path_prefix != '.':
            subtree_git_path_prefix = yaml_expand_global_string(subtree_git_path_prefix)
          else:
            subtree_git_path_prefix = ''

          subtree_svn_path_prefix = subtree_row['svn_path_prefix'].strip()
          if subtree_svn_path_prefix != '.':
            subtree_svn_path_prefix = yaml_expand_global_string(subtree_svn_path_prefix)
          else:
            subtree_svn_path_prefix = ''

          subtree_svn_repopath = subtree_svn_reporoot + (('/' + subtree_svn_path_prefix) if subtree_svn_path_prefix != '' else '')

          subtree_remote_name_prefix_str = '| ' * (parent_nest_index + 1)

          row_values = [subtree_remote_name_prefix_str + subtree_remote_name, subtree_git_reporoot, subtree_parent_git_path_prefix,
            subtree_svn_repopath, subtree_git_local_branch, subtree_git_remote_branch]
          git_print_repos_list_row(row_values, column_widths)

          if subtree_remote_name in remote_name_list:
            raise Exception('remote_name must be unique in the repositories list for the same scm_token')

          remote_name_list.append(subtree_remote_name)

          ref_child_repo_params = parent_tuple_ref[2]

          if subtree_remote_name in ref_child_repo_params:
            raise Exception('subtree_remote_name must be unique in the ref_child_repo_params')

          child_tuple_ref = ref_child_repo_params[subtree_remote_name] = (
            {
              'ordinal_index'                 : ordinal_index,
              'ordinal_index_prefix_str'      : '',
              'nest_index'                    : parent_nest_index + 1,
              'parent_tuple_ref'              : parent_tuple_ref,
              'children_tuple_ref_list'       : [],                       # empty list if have has no children
              'num_on_level_and_above'        : 0,                        # not yet known
              'num_on_level'                  : 0,                        # not yet known
              'remote_name'                   : subtree_remote_name,
              'parent_remote_name'            : parent_remote_name,
              'git_reporoot'                  : subtree_git_reporoot,
              'parent_git_path_prefix'        : subtree_parent_git_path_prefix,
              'svn_reporoot'                  : subtree_svn_reporoot,
              'svn_repo_uuid'                 : '',
              'git_path_prefix'               : subtree_git_path_prefix,
              'svn_path_prefix'               : subtree_svn_path_prefix,
              'git_local_branch'              : subtree_git_local_branch,
              'git_remote_branch'             : subtree_git_remote_branch,
              'git_wcroot'                    : '',
              'git_ignore_paths_regex'        : ''
            },
            # must be assigned at once, otherwise: `TypeError: 'tuple' object does not support item assignment`
            {},
            {}
          )

          ordinal_index += 1

          git_svn_repo_tree_tuple_ref_preorder_list.append(child_tuple_ref)

          last_parent_refs_on_next_level_to_update.append(child_tuple_ref)

          # push to front instead of popped
          parent_child_remote_names_to_parse.insert(insert_to_front_index, child_tuple_ref)
          insert_to_front_index += 1

    if len(parent_child_remote_names_to_parse) == 0:
      break

  if len(last_parent_refs_on_next_level_to_update) != 0:
    raise Exception('invalid size of last_parent_refs_on_next_level_to_update, must be empty: size={0}'.format(len(last_parent_refs_on_next_level_to_update)))
  if last_num_children_on_next_level != 0:
    raise Exception('invalid value of last_num_children_on_next_level: value={0}'.format(last_num_children_on_next_level))

  # update the last level elements
  for parent_ref_to_update in last_parent_refs_on_prev_level_to_update:
    parent_repo_params_to_update = parent_ref_to_update[0]

    parent_parent_repo_tuple_ref = parent_repo_params_to_update['parent_tuple_ref']
    parent_parent_repo_params = parent_parent_repo_tuple_ref[0] if not parent_parent_repo_tuple_ref is None else None

    parent_parent_num_on_level_and_above = parent_parent_repo_params['num_on_level_and_above'] if not parent_parent_repo_params is None else 1 # 1 - the root only

    parent_repo_params_to_update['num_on_level_and_above'] = parent_parent_num_on_level_and_above + last_num_children_on_prev_level
    parent_repo_params_to_update['num_on_level'] = last_num_children_on_prev_level

  if last_num_children_on_prev_level > 0:
    # save elements from next level
    num_elems_per_level.append(last_num_children_on_prev_level)

  # calculate `git_log_list_child_max_depth_fetch`
  level_index = 3
  num_elems_on_level_and_above = 1 # from the root
  for num_elems_on_level in num_elems_per_level:
    num_elems_on_level_and_above += num_elems_on_level
    git_log_list_child_max_depth_fetch += num_elems_on_level_and_above * math.log2(level_index)
    level_index += 1

  # rounding to integer
  git_log_list_child_max_depth_fetch = int(git_log_list_child_max_depth_fetch+ 1)

  git_svn_params_dict['git_log_list_child_max_depth_fetch'] = git_log_list_child_max_depth_fetch

  git_print_repos_list_footer(column_widths)

  print('- Indexing children for each parent GIT/SVN repository...')

  git_svn_repo_tree_tuple_ref_index = 0
  git_svn_repo_tree_tuple_ref_preorder_list_size = len(git_svn_repo_tree_tuple_ref_preorder_list)

  ordinal_index_max_num_digits = int(math.log10(git_svn_repo_tree_tuple_ref_preorder_list_size)) + 1
  if ordinal_index_max_num_digits < 2:
    ordinal_index_max_num_digits = 2

  for git_svn_repo_tree_tuple_ref in git_svn_repo_tree_tuple_ref_preorder_list:
    parent_repo_params_ref = git_svn_repo_tree_tuple_ref[0]

    ordinal_index = parent_repo_params_ref['ordinal_index']
    ordinal_index_num_digits = (int(math.log10(ordinal_index)) if ordinal_index > 0 else 0) + 1

    ordinal_index_prefix_str = ((ordinal_index_max_num_digits - ordinal_index_num_digits) * '0') + str(ordinal_index)

    parent_repo_params_ref['ordinal_index_prefix_str'] = ordinal_index_prefix_str

    parent_parent_tuple_ref = parent_repo_params_ref['parent_tuple_ref']

    remote_name = parent_repo_params_ref['remote_name']

    parent_git_path_prefix = parent_repo_params_ref['parent_git_path_prefix']

    if not parent_parent_tuple_ref is None:
      parent_repo_params_ref['git_wcroot'] = get_git_subtree_wcroot(ordinal_index_prefix_str + '--', git_subtrees_root, remote_name, parent_git_path_prefix)

    # optimization: skip the search if less than that
    children_nest_index = parent_repo_params_ref['nest_index'] + 1

    children_tuple_ref_list = parent_repo_params_ref['children_tuple_ref_list']

    next_child_git_svn_repo_tree_tuple_ref_index = git_svn_repo_tree_tuple_ref_index + 1
    while next_child_git_svn_repo_tree_tuple_ref_index < git_svn_repo_tree_tuple_ref_preorder_list_size:
      child_git_svn_repo_tree_tuple_ref = \
        git_svn_repo_tree_tuple_ref_preorder_list[next_child_git_svn_repo_tree_tuple_ref_index]

      child_repo_params_ref = child_git_svn_repo_tree_tuple_ref[0]
      child_nest_index = child_repo_params_ref['nest_index']

      if child_nest_index < children_nest_index:
        break
      elif child_nest_index == children_nest_index:
        child_parent_tuple_ref = child_repo_params_ref['parent_tuple_ref']
        if child_parent_tuple_ref is git_svn_repo_tree_tuple_ref: # just in case
          children_tuple_ref_list.append(child_git_svn_repo_tree_tuple_ref)

      next_child_git_svn_repo_tree_tuple_ref_index += 1

    # generate `--ignore_paths` from child repositories

    parent_repo_params_ref['git_ignore_paths_regex'] = \
      get_git_svn_subtree_ignore_paths_regex_from_parent_ref(git_svn_repo_tree_tuple_ref, children_tuple_ref_list)

    git_svn_repo_tree_tuple_ref_index += 1

  svn_repo_root_to_uuid_dict = None

  if update_svn_repo_uuid:
    print('- Updating SVN repositories info...')

    svn_repo_root_to_uuid_dict = {}

    for git_svn_repo_tree_tuple_ref in git_svn_repo_tree_tuple_ref_preorder_list:
      repo_params_ref = git_svn_repo_tree_tuple_ref[0]

      svn_reporoot = repo_params_ref['svn_reporoot']

      if svn_reporoot not in svn_repo_root_to_uuid_dict.keys():
        ret = call_svn(['info', '--show-item', 'repos-uuid', svn_reporoot])

        svn_repo_uuid = ret[1].strip()
        if svn_repo_uuid != '':
          svn_repo_root_to_uuid_dict[svn_reporoot] = repo_params_ref['svn_repo_uuid'] = svn_repo_uuid
      else:
        repo_params_ref['svn_repo_uuid'] = svn_repo_root_to_uuid_dict[svn_reporoot]

  print('- Checking children GIT/SVN repositories on compatability with the root...')

  root_repo_tuple_ref = git_svn_repo_tree_tuple_ref_preorder_list[0]
  root_repo_params_ref = root_repo_tuple_ref[0]
  root_svn_repo_uuid = root_repo_params_ref['svn_repo_uuid']

  if len(root_svn_repo_uuid) > 0:
    for git_svn_repo_tree_tuple_ref in git_svn_repo_tree_tuple_ref_preorder_list:
      repo_params_ref = git_svn_repo_tree_tuple_ref[0]

      parent_tuple_ref = repo_params_ref['parent_tuple_ref']
      if not parent_tuple_ref is None:
        children_dict_ref = git_svn_repo_tree_tuple_ref[2]
        # if have has no children then can have has a different repository UUID
        if len(children_dict_ref) > 0:
          svn_repo_uuid = root_repo_params_ref['svn_repo_uuid']
          if len(svn_repo_uuid) > 0 and svn_repo_uuid != repo_params_ref['svn_repo_uuid']:
            raise Exception('all not leaf GIT repositories must have has the same SVN repository UUID as the root GIT repository')

  return (git_svn_repo_tree_dict, git_svn_repo_tree_tuple_ref_preorder_list, svn_repo_root_to_uuid_dict, git_svn_params_dict)

def get_git_svn_repos_list_table_params():
  return (
    ['<remote_name>', '<git_reporoot>', '<parent_git_prefix>', '<svn_repopath>', '<git_local_branch>', '<git_remote_branch>'],
    [20, 64, 20, 64, 20, 20]
  )

def get_max_time_depth_in_multiple_svn_commits_fetch_sec():
  # maximal time depth in a multiple svn commits fetch from an svn repository
  return 2678400 # seconds in 1 month (31 days)

def get_root_min_tree_time_of_last_notpushed_svn_commit(git_svn_repo_tree_tuple_ref_preorder_list):
  git_svn_repo_tree_tuple_root_ref = git_svn_repo_tree_tuple_ref_preorder_list[0]
  repo_params_root_ref = git_svn_repo_tree_tuple_root_ref[0]
  if not repo_params_root_ref['parent_tuple_ref'] is None:
    raise Exception('first element in git_svn_repo_tree_tuple_ref_preorder_list is not a tree root')
  fetch_state_root_ref = git_svn_repo_tree_tuple_root_ref[1]
  min_tree_time_of_last_notpushed_svn_commit = fetch_state_root_ref['min_tree_time_of_last_notpushed_svn_commit']
  return min_tree_time_of_last_notpushed_svn_commit

def print_root_min_tree_time_of_last_notpushed_svn_commit(prefix_str, git_svn_repo_tree_tuple_ref_preorder_list, suffix_str = ''):
  min_tree_time_of_last_notpushed_svn_commit = get_root_min_tree_time_of_last_notpushed_svn_commit(git_svn_repo_tree_tuple_ref_preorder_list)
  column_fmt_str = '{:<{}} {:<{}} {:<{}} {:<{}}'
  row_values = [prefix_str, 'root_min_tree_time_of_last_notpushed_svn_commit:', str(min_tree_time_of_last_notpushed_svn_commit[0]) +
    ' {' + min_tree_time_of_last_notpushed_svn_commit[1] + '}', suffix_str]
  column_widths = [3, 52, 40, 20]
  git_print_repos_list_row(row_values, column_widths, column_fmt_str)

def get_subtree_min_ro_tree_time_of_first_notpushed_svn_commit(git_svn_repo_tree_tuple_ref):
  fetch_state_ref = git_svn_repo_tree_tuple_ref[1]
  min_ro_tree_time_of_first_notpushed_svn_commit = fetch_state_ref['min_ro_tree_time_of_first_notpushed_svn_commit']
  return min_ro_tree_time_of_first_notpushed_svn_commit

def get_root_min_ro_tree_time_of_first_notpushed_svn_commit(git_svn_repo_tree_tuple_ref_preorder_list):
  git_svn_repo_tree_tuple_root_ref = git_svn_repo_tree_tuple_ref_preorder_list[0]
  repo_params_root_ref = git_svn_repo_tree_tuple_root_ref[0]
  if not repo_params_root_ref['parent_tuple_ref'] is None:
    raise Exception('first element in git_svn_repo_tree_tuple_ref_preorder_list is not a tree root')
  return get_subtree_min_ro_tree_time_of_first_notpushed_svn_commit(git_svn_repo_tree_tuple_root_ref)

def print_root_min_ro_tree_time_of_first_notpushed_svn_commit(prefix_str, git_svn_repo_tree_tuple_ref_preorder_list, suffix_str = ''):
  min_ro_tree_time_of_first_notpushed_svn_commit = get_root_min_ro_tree_time_of_first_notpushed_svn_commit(git_svn_repo_tree_tuple_ref_preorder_list)
  if not min_ro_tree_time_of_first_notpushed_svn_commit is None:
    column_fmt_str = '{:<{}} {:<{}} {:<{}} {:<{}}'
    row_values = [prefix_str, 'root_min_ro_tree_time_of_first_notpushed_svn_commit:', str(min_ro_tree_time_of_first_notpushed_svn_commit[0]) +
      ' {' + min_ro_tree_time_of_first_notpushed_svn_commit[1] + '}', suffix_str]
    column_widths = [3, 52, 40, 20]
    git_print_repos_list_row(row_values, column_widths, column_fmt_str)

def update_git_svn_repo_fetch_state(git_svn_repo_tree_tuple_ref_preorder_list, git_svn_params_dict,
                                    max_time_depth_in_multiple_svn_commits_fetch_sec, is_first_time_update, root_only = False):
  print('- Updating GIT-SVN repositories fetch state...')

  max_time_depth_in_multiple_svn_commits_fetch_sec = get_max_time_depth_in_multiple_svn_commits_fetch_sec()

  # The loop  is required here because the first request can return empty list because no commits can be found for a time frame
  while True:
    current_timestamp = datetime.utcnow().timestamp()

    notpushed_svn_commit_all_list_len = 0

    for git_svn_repo_tree_tuple_ref in git_svn_repo_tree_tuple_ref_preorder_list:
      repo_params_ref = git_svn_repo_tree_tuple_ref[0]
      fetch_state_ref = git_svn_repo_tree_tuple_ref[1]

      remote_name = repo_params_ref['remote_name']
      git_reporoot = repo_params_ref['git_reporoot']
      svn_reporoot = repo_params_ref['svn_reporoot']
      git_local_branch = repo_params_ref['git_local_branch']
      git_remote_branch = repo_params_ref['git_remote_branch']
      git_path_prefix = repo_params_ref['git_path_prefix']
      svn_path_prefix = repo_params_ref['svn_path_prefix']
      git_wcroot = repo_params_ref['git_wcroot']

      svn_repopath = svn_reporoot + (('/' + svn_path_prefix) if svn_path_prefix != '' else '')

      with conditional(git_wcroot != '.', local_cwd(' ->> cwd: `{0}`...', ' -<< cwd: `{0}`...', git_wcroot)):
        git_remote_refspec_token, git_remote_local_refspec_token = \
          get_git_remote_refspec_token_tuple(remote_name, git_local_branch, git_remote_branch)

        # get last pushed commit hash
        git_last_pushed_commit_hash = get_git_last_pushed_commit_hash(git_reporoot, git_remote_local_refspec_token)

        last_pushed_git_svn_commit_rev = 0
        last_pushed_git_svn_commit_hash = None
        last_pushed_git_svn_commit_author_timestamp = None
        last_pushed_git_svn_commit_author_date_time = None
        last_pushed_git_svn_commit_commit_timestamp = None
        last_pushed_git_svn_commit_commit_date_time = None
        last_pushed_git_svn_commit_fetch_timestamp = None

        if not git_last_pushed_commit_hash is None:
          # get last git-svn revision w/o fetch because it must be already fetched

          last_pushed_git_svn_commit_rev, last_pushed_git_svn_commit_hash, \
          last_pushed_git_svn_commit_author_timestamp, last_pushed_git_svn_commit_author_date_time, \
          last_pushed_git_svn_commit_commit_timestamp, last_pushed_git_svn_commit_commit_date_time, \
          num_overall_git_commits, \
          last_pushed_git_svn_commit_fetch_timestamp = \
            get_last_git_svn_rev_by_git_log(git_remote_refspec_token, svn_reporoot, svn_path_prefix, git_path_prefix,
              git_svn_params_dict)

          if last_pushed_git_svn_commit_hash is None:
            raise Exception('last git-svn commit is not found in the git log output: git_path_prefix=`{0}` svn_repopath=`{1}`'.
              format(git_path_prefix, svn_repopath))

        # update git-svn commit author timestamp and datetime (just in case)
        if last_pushed_git_svn_commit_rev > 0:
          # CAUTION:
          #   1. This is still required because a child repository can be pushed externally to that algorithm without a proper author time update
          #      (for example, the smartgit does so), so we have to request associated commit author time directly from the svn repository.
          #

          # request `last_pushed_git_svn_commit_author_timestamp` and `last_pushed_git_svn_commit_author_date_time` from svn by last_pushed_git_svn_commit_rev
          target_svn_commit_list = get_svn_commit_list(svn_repopath, 1, last_pushed_git_svn_commit_rev)
          if target_svn_commit_list is None:
            raise Exception('revision number is not found in the svn log: rev={0} repopath=`{1}`'.format(last_pushed_git_svn_commit_rev, svn_repopath))

          # update to actual svn commit timestamp and date time
          target_svn_commit = target_svn_commit_list[0]

          target_svn_commit_rev = target_svn_commit[0]
          if target_svn_commit_rev != last_pushed_git_svn_commit_rev:
            raise Exception('svn log returned invalid svn revision: requested=' + last_pushed_git_svn_commit_rev + ' returned=' + target_svn_commit_rev)

          last_pushed_git_svn_commit_author_timestamp = target_svn_commit[2]
          last_pushed_git_svn_commit_author_date_time = target_svn_commit[3]

        # get svn revision list not pushed into respective git repository

        # CAUTION:
        #   1. To make the same output for range of 2 revisions but using a date/time of 2 revisions the both
        #      boundaries must be offsetted by +1 second.
        #   2. If the range parameter in the `svn log ...` command consists only one boundary, then it is
        #      used the same way and must be offsetted by `+1` second to request the revision existed in not
        #      offsetted date/time.
        #

        if last_pushed_git_svn_commit_rev > 0:
          git_svn_next_fetch_timestamp = last_pushed_git_svn_commit_author_timestamp + max_time_depth_in_multiple_svn_commits_fetch_sec + 1
          git_svn_end_fetch_timestamp = git_svn_next_fetch_timestamp

          # request svn commits limited by a maximal time depth for a multiple svn commits fetch
          to_svn_rev_date_time = datetime.fromtimestamp(git_svn_end_fetch_timestamp, tz = tzlocal.get_localzone()).strftime('%Y-%m-%d %H:%M:%S %z')
          notpushed_svn_commit_list = get_svn_commit_list(svn_repopath, '*', last_pushed_git_svn_commit_rev + 1, '{' + to_svn_rev_date_time + '}')

          last_notpushed_svn_commit_fetch_end_timestamp = git_svn_end_fetch_timestamp
        else:
          # we must test an svn repository on emptiness before call to `svn log ...`
          ret = call_svn(['info', '--show-item', 'last-changed-revision', svn_reporoot])

          svn_last_changed_rev = ret[1].strip()
          if len(svn_last_changed_rev) > 0:
            svn_last_changed_rev = int(svn_last_changed_rev)
          else:
            svn_last_changed_rev = 0

          if svn_last_changed_rev > 0:
            # request the first commit to retrieve the commit timestamp to make offset from it
            notpushed_svn_commit_list = get_svn_commit_list(svn_repopath, 1, 1, 'HEAD')

            first_notpushed_svn_commit = notpushed_svn_commit_list[0]

            svn_first_commit_timestamp = first_notpushed_svn_commit[2]

            git_svn_next_fetch_timestamp = svn_first_commit_timestamp + max_time_depth_in_multiple_svn_commits_fetch_sec + 1
            git_svn_end_fetch_timestamp = git_svn_next_fetch_timestamp

            # request svn commits limited by a maximal time depth for a multiple svn commits fetch
            to_svn_rev_date_time = datetime.fromtimestamp(git_svn_end_fetch_timestamp, tz = tzlocal.get_localzone()).strftime('%Y-%m-%d %H:%M:%S %z')
            notpushed_svn_commit_list = get_svn_commit_list(svn_repopath, '*', 1, '{' + to_svn_rev_date_time + '}')

            last_notpushed_svn_commit_fetch_end_timestamp = git_svn_end_fetch_timestamp
          else:
            git_svn_next_fetch_timestamp = None
            notpushed_svn_commit_list = None
            last_notpushed_svn_commit_fetch_end_timestamp = None

        parent_tuple_ref = repo_params_ref['parent_tuple_ref']
        if not parent_tuple_ref is None:
          parent_repo_params_ref = parent_tuple_ref[0]
          parent_svn_repo_uuid = parent_repo_params_ref['svn_repo_uuid']
          child_svn_repo_uuid = repo_params_ref['svn_repo_uuid']
          parent_repo_params_ref = parent_tuple_ref[0]
          if len(parent_svn_repo_uuid) > 0 and len(child_svn_repo_uuid) and parent_svn_repo_uuid == child_svn_repo_uuid:
            is_read_only_repo = False
          else:
            # the whole subtree becomes read only if even one of 2 UUID of SVN repository is not known or not reachable
            is_read_only_repo = True
        else:
          # the root always writable
          is_read_only_repo = False

        fetch_state_ref['is_read_only_repo'] = is_read_only_repo
        if is_first_time_update:
          # would be updated later after the first prune
          fetch_state_ref['last_pruned_git_svn_commit_dict'] = {}

          fetch_state_ref['is_first_time_push'] = True

        # fix up `notpushed_svn_commit_list` if less or equal to the `last_pushed_git_svn_commit`
        if not notpushed_svn_commit_list is None:
          for notpushed_svn_commit in list(notpushed_svn_commit_list):
            if last_pushed_git_svn_commit_rev < notpushed_svn_commit[0]:
              break
            notpushed_svn_commit_list.pop(0)

        notpushed_svn_commit_list_len = len(notpushed_svn_commit_list) if not notpushed_svn_commit_list is None else 0
        if notpushed_svn_commit_list_len > 0:
          last_notpushed_svn_commit = notpushed_svn_commit_list[notpushed_svn_commit_list_len - 1]
          fetch_state_ref['min_tree_time_of_last_notpushed_svn_commit'] = (*last_notpushed_svn_commit[2:4], git_svn_repo_tree_tuple_ref)
          if is_read_only_repo:
            first_notpushed_svn_commit = notpushed_svn_commit_list[0]
            fetch_state_ref['min_ro_tree_time_of_first_notpushed_svn_commit'] = (*first_notpushed_svn_commit[2:4], git_svn_repo_tree_tuple_ref)
          else:
            fetch_state_ref['min_ro_tree_time_of_first_notpushed_svn_commit'] = None
        else:
          # no notpushed svn commits
          fetch_state_ref['min_tree_time_of_last_notpushed_svn_commit'] = None
          fetch_state_ref['min_ro_tree_time_of_first_notpushed_svn_commit'] = None
          notpushed_svn_commit_list = None # to reset to None if empty list

        # accumulate `notpushed_svn_commit_list` size
        notpushed_svn_commit_all_list_len += notpushed_svn_commit_list_len

        # CAUTION:
        #   If has no pushed commits, then the `last_pushed_git_svn_commit_rev` is not `None` and equals to `0`, when
        #   all the rest are None.
        #
        fetch_state_ref['last_pushed_git_svn_commit'] = (
          last_pushed_git_svn_commit_rev,
          last_pushed_git_svn_commit_hash,
          int(last_pushed_git_svn_commit_author_timestamp) if not last_pushed_git_svn_commit_author_timestamp is None else None,
          last_pushed_git_svn_commit_author_date_time,
          int(last_pushed_git_svn_commit_commit_timestamp) if not last_pushed_git_svn_commit_commit_timestamp is None else None,
          last_pushed_git_svn_commit_commit_date_time
        )
        fetch_state_ref['last_pushed_git_svn_commit_fetch_timestamp'] = last_pushed_git_svn_commit_fetch_timestamp

        fetch_state_ref['notpushed_svn_commit_list'] = notpushed_svn_commit_list
        fetch_state_ref['first_advanced_notpushed_svn_commit'] = None
        fetch_state_ref['last_notpushed_svn_commit_fetch_end_timestamp'] = last_notpushed_svn_commit_fetch_end_timestamp

        print('---')

        if parent_tuple_ref is None and root_only:
          break

    if notpushed_svn_commit_all_list_len > 0:
      break

    # no not pushed commits or a fetch time frame is out of current timestamp
    if git_svn_next_fetch_timestamp is None or current_timestamp < git_svn_next_fetch_timestamp:
      break

    # increase svn log size request
    max_time_depth_in_multiple_svn_commits_fetch_sec *= 2

  if not root_only:
    print('- Updating `min_tree_time_of_last_notpushed_svn_commit`/`min_ro_tree_time_of_first_notpushed_svn_commit`...')

    for git_svn_repo_tree_tuple_ref in reversed(git_svn_repo_tree_tuple_ref_preorder_list): # in reverse
      child_repo_params_ref = git_svn_repo_tree_tuple_ref[0]
      parent_tuple_ref = child_repo_params_ref['parent_tuple_ref']

      if not parent_tuple_ref is None:
        child_fetch_state_ref = git_svn_repo_tree_tuple_ref[1]

        parent_fetch_state_ref = parent_tuple_ref[1]

        child_min_tree_time_of_last_notpushed_svn_commit = child_fetch_state_ref['min_tree_time_of_last_notpushed_svn_commit']
        if not child_min_tree_time_of_last_notpushed_svn_commit is None:
          parent_min_tree_time_of_last_notpushed_svn_commit = parent_fetch_state_ref['min_tree_time_of_last_notpushed_svn_commit']
          if not parent_min_tree_time_of_last_notpushed_svn_commit is None:
            if child_min_tree_time_of_last_notpushed_svn_commit[0] < parent_min_tree_time_of_last_notpushed_svn_commit[0]:
              parent_fetch_state_ref['min_tree_time_of_last_notpushed_svn_commit'] = child_min_tree_time_of_last_notpushed_svn_commit
          else:
            parent_fetch_state_ref['min_tree_time_of_last_notpushed_svn_commit'] = child_min_tree_time_of_last_notpushed_svn_commit

        child_min_ro_tree_time_of_first_notpushed_svn_commit = child_fetch_state_ref['min_ro_tree_time_of_first_notpushed_svn_commit']
        if not child_min_ro_tree_time_of_first_notpushed_svn_commit is None:
          parent_min_ro_tree_time_of_first_notpushed_svn_commit = parent_fetch_state_ref['min_ro_tree_time_of_first_notpushed_svn_commit']
          if not parent_min_ro_tree_time_of_first_notpushed_svn_commit is None:
            if child_min_ro_tree_time_of_first_notpushed_svn_commit[0] < parent_min_ro_tree_time_of_first_notpushed_svn_commit [0]:
              parent_fetch_state_ref['min_ro_tree_time_of_first_notpushed_svn_commit'] = child_min_ro_tree_time_of_first_notpushed_svn_commit
          else:
            parent_fetch_state_ref['min_ro_tree_time_of_first_notpushed_svn_commit'] = child_min_ro_tree_time_of_first_notpushed_svn_commit

  if notpushed_svn_commit_all_list_len == 0:
    print('  No not pushed SVN revisions to update.')
    return False

  print('- Updated GIT-SVN repositories:')

  column_names = ['<remote_name>', '<last_pushed_git_svn_commit>', '<notpushed_svn_commit_list>', '<min_ro_tree_time_of_first_notpushed_svn_commit>', '<fetch_rev>', '<RO>']
  column_widths = [20, 48, 36, 47, 11, 4]

  git_print_repos_list_header(column_names, column_widths)

  for git_svn_repo_tree_tuple_ref in git_svn_repo_tree_tuple_ref_preorder_list:
    repo_params_ref = git_svn_repo_tree_tuple_ref[0]
    fetch_state_ref = git_svn_repo_tree_tuple_ref[1]

    repo_nest_index = repo_params_ref['nest_index']
    remote_name = repo_params_ref['remote_name']

    is_read_only_repo = fetch_state_ref['is_read_only_repo']
    min_ro_tree_time_of_first_notpushed_svn_commit = fetch_state_ref['min_ro_tree_time_of_first_notpushed_svn_commit']
    notpushed_svn_commit_list = fetch_state_ref['notpushed_svn_commit_list']
    last_pushed_git_svn_commit = fetch_state_ref['last_pushed_git_svn_commit']
    last_pushed_git_svn_commit_rev = last_pushed_git_svn_commit[0]

    remote_name_prefix_str = '| ' * repo_nest_index

    # can be less or equal to the pushed one, we have to intercept that
    is_first_notpushed_svn_commit_invalid = False

    notpushed_svn_commit_list_str = ''
    if not notpushed_svn_commit_list is None:
      notpushed_svn_commit_list_len = len(notpushed_svn_commit_list)
      if notpushed_svn_commit_list_len > 0:
        # validate first not pushed svn revision
        if last_pushed_git_svn_commit_rev >= notpushed_svn_commit_list[0][0]:
          is_first_notpushed_svn_commit_invalid = True

        if notpushed_svn_commit_list_len > 4:
          notpushed_svn_commit_list_str = '[' + \
            str(notpushed_svn_commit_list[0][0]) + r' ' + str(notpushed_svn_commit_list[1][0]) + ' ... ' + \
            str(notpushed_svn_commit_list[-2][0]) + r' ' + str(notpushed_svn_commit_list[-1][0]) + ']'
        else:
          text = ''
          for notpushed_svn_commit in notpushed_svn_commit_list:
            if len(text) > 0:
              text += r' '
            text += str(notpushed_svn_commit[0])
          notpushed_svn_commit_list_str = '[' + text + ']'

    last_pushed_git_svn_commit_rev_str = 'r' + str(last_pushed_git_svn_commit_rev)
    last_pushed_git_svn_commit_rev_str_len = len(last_pushed_git_svn_commit_rev_str)

    last_pushed_git_svn_commit_rev_str_max_len = 9

    row_values = [
      remote_name_prefix_str + remote_name,
      last_pushed_git_svn_commit_rev_str + (' ' * max(1, last_pushed_git_svn_commit_rev_str_max_len + 1 - last_pushed_git_svn_commit_rev_str_len)) + \
        (str(last_pushed_git_svn_commit[2]) + ' {' + last_pushed_git_svn_commit[3] + '}') if last_pushed_git_svn_commit_rev > 0 else '',
      notpushed_svn_commit_list_str,
      (str(min_ro_tree_time_of_first_notpushed_svn_commit[0]) + ' {' + min_ro_tree_time_of_first_notpushed_svn_commit[1] + '}') \
        if not min_ro_tree_time_of_first_notpushed_svn_commit is None else '',
      'r' + str(last_pushed_git_svn_commit_rev),
      'Y' if is_read_only_repo else ''
    ]
    git_print_repos_list_row(row_values, column_widths)

  git_print_repos_list_footer(column_widths)

  print_root_min_tree_time_of_last_notpushed_svn_commit('  * - ', git_svn_repo_tree_tuple_ref_preorder_list)

  if is_first_notpushed_svn_commit_invalid:
    raise Exception('one or more git-svn repositories contains a not pushed svn revision less or equal to the last pushed one')

  return True

def git_fetch(configure_dir, scm_token, git_subtrees_root = None, root_only = False, reset_hard = False, prune_empty_git_svn_commits = True,
              update_svn_repo_uuid = False, verbosity = 0):
  print("git_fetch: {0}".format(configure_dir))

  set_verbosity_level(verbosity)

  if not git_subtrees_root is None:
    print(' * git_subtrees_root: `' + git_subtrees_root + '`')

  if configure_dir == '':
    print_err("{0}: error: configure directory is not defined.".format(sys.argv[0]))
    return 1

  if configure_dir[-1:] in ['\\', '/']:
    configure_dir = configure_dir[:-1]

  if not os.path.isdir(configure_dir):
    print_err("{0}: error: configure directory does not exist: `{1}`.".format(sys.argv[0], configure_dir))
    return 32

  if not git_subtrees_root is None and not os.path.isdir(git_subtrees_root):
    print_err("{0}: error: git subtrees root directory does not exist: git_subtrees_root=`{1}`.".format(sys.argv[0], git_subtrees_root))
    return 33

  wcroot_dir = getglobalvar(scm_token + '.WCROOT_DIR')
  if wcroot_dir == '': return -254
  if WCROOT_OFFSET == '': return -253

  wcroot_path = os.path.abspath(os.path.join(WCROOT_OFFSET, wcroot_dir)).replace('\\', '/')

  git_user = getglobalvar(scm_token + '.USER')
  git_email = getglobalvar(scm_token + '.EMAIL')

  if not os.path.exists(wcroot_path):
    os.mkdir(wcroot_path)

  max_time_depth_in_multiple_svn_commits_fetch_sec = get_max_time_depth_in_multiple_svn_commits_fetch_sec()

  with local_cwd(' ->> cwd: `{0}`...', ' -<< cwd: `{0}`...', wcroot_path), \
       GitReposListReader(configure_dir + '/git_repos.lst') as git_repos_reader, ServiceProcCache() as svc_proc_cache:
    executed_procs = cache_init_service_proc(svc_proc_cache)

    with tkl.OnExit(lambda: cache_close_running_procs(executed_procs, svc_proc_cache)):
      column_names, column_widths = get_git_svn_repos_list_table_params()

      if git_subtrees_root is None:
        git_subtrees_root = wcroot_path + '/.git/.pyxvcs/gitwc'

      git_svn_repo_tree_dict, git_svn_repo_tree_tuple_ref_preorder_list, svn_repo_root_to_uuid_dict, git_svn_params_dict = \
        read_git_svn_repo_list(git_repos_reader, scm_token, wcroot_path, git_subtrees_root, column_names, column_widths,
          update_svn_repo_uuid = update_svn_repo_uuid)

      print('- GIT fetching...')

      for git_svn_repo_tree_tuple_ref in git_svn_repo_tree_tuple_ref_preorder_list:
        repo_params_ref = git_svn_repo_tree_tuple_ref[0]

        parent_tuple_ref = repo_params_ref['parent_tuple_ref']

        ordinal_index_prefix_str = repo_params_ref['ordinal_index_prefix_str']

        remote_name = repo_params_ref['remote_name']
        parent_remote_name = repo_params_ref['parent_remote_name']

        git_reporoot = repo_params_ref['git_reporoot']
        svn_reporoot = repo_params_ref['svn_reporoot']

        parent_git_path_prefix = repo_params_ref['parent_git_path_prefix']

        git_local_branch = repo_params_ref['git_local_branch']
        git_remote_branch = repo_params_ref['git_remote_branch']

        if not parent_tuple_ref is None:
          subtree_git_wcroot = repo_params_ref['git_wcroot']

        with conditional(not parent_tuple_ref is None,
                         local_cwd(' ->> cwd: `{0}`...', ' -<< cwd: `{0}`...', subtree_git_wcroot) if not parent_tuple_ref is None else None):
          git_remote_refspec_token, git_remote_local_refspec_token = \
            get_git_remote_refspec_token_tuple(remote_name, git_local_branch, git_remote_branch)

          # get last pushed commit hash
          git_last_pushed_commit_hash = get_git_last_pushed_commit_hash(git_reporoot, git_remote_local_refspec_token)

          if not git_last_pushed_commit_hash is None:
            git_fetch_refspec_token = get_git_fetch_refspec_token(git_local_branch, git_remote_branch)

            call_git(['fetch', remote_name, git_fetch_refspec_token])

          # 1. compare the last pushed commit hash with the last fetched commit hash and if different, then revert FETCH_HEAD
          # 2. additionally, compare the last pushed commit hash with the head commit hash and if different then revert HEAD

          git_local_refspec_token = get_git_local_refspec_token(git_local_branch, git_remote_branch)

          git_reset_if_head_is_not_last_pushed(git_last_pushed_commit_hash, git_local_refspec_token, git_remote_refspec_token,
            reset_hard = reset_hard)

          print('---')

          if parent_tuple_ref is None and root_only:
            break

      update_git_svn_repo_fetch_state(git_svn_repo_tree_tuple_ref_preorder_list, git_svn_params_dict,
        max_time_depth_in_multiple_svn_commits_fetch_sec, root_only = root_only, is_first_time_update = True)

      print('- GIT-SVN fetching...')

      for git_svn_repo_tree_tuple_ref in git_svn_repo_tree_tuple_ref_preorder_list:
        repo_params_ref = git_svn_repo_tree_tuple_ref[0]
        fetch_state_ref = git_svn_repo_tree_tuple_ref[1]

        parent_tuple_ref = repo_params_ref['parent_tuple_ref']

        ordinal_index_prefix_str = repo_params_ref['ordinal_index_prefix_str']

        remote_name = repo_params_ref['remote_name']

        git_reporoot = repo_params_ref['git_reporoot']
        svn_reporoot = repo_params_ref['svn_reporoot']

        parent_git_path_prefix = repo_params_ref['parent_git_path_prefix']

        git_local_branch = repo_params_ref['git_local_branch']
        git_remote_branch = repo_params_ref['git_remote_branch']

        git_svn_fetch_ignore_paths_regex = repo_params_ref['git_ignore_paths_regex']

        if not parent_tuple_ref is None:
          subtree_git_wcroot = repo_params_ref['git_wcroot']

        with conditional(not parent_tuple_ref is None,
                         local_cwd(' ->> cwd: `{0}`...', ' -<< cwd: `{0}`...', subtree_git_wcroot) if not parent_tuple_ref is None else None):
          last_pruned_git_svn_commit_dict = fetch_state_ref['last_pruned_git_svn_commit_dict']

          git_svn_fetch_cmdline_list = []

          if len(git_svn_fetch_ignore_paths_regex) > 0:
            git_svn_fetch_cmdline_list.append('--ignore-paths=' + git_svn_fetch_ignore_paths_regex)

          # git-svn (re)fetch next svn revision

          git_local_refspec_token = get_git_local_refspec_token(git_local_branch, git_remote_branch)
          git_remote_refspec_token, git_remote_local_refspec_token = \
            get_git_remote_refspec_token_tuple(remote_name, git_local_branch, git_remote_branch)

          # get last pushed commit hash
          git_last_pushed_commit_hash = get_git_last_pushed_commit_hash(git_reporoot, git_remote_local_refspec_token)

          if not git_last_pushed_commit_hash is None:
            # CAUTION:
            #   1. The index file cleanup might be required here to avoid the error messsage:
            #      `fatal: cannot switch branch while merging`
            #   2. The Working Copy cleanup is required together with the index file cleanup to avoid later a problem with a
            #      merge around untracked files with the error message:
            #      `error: The following untracked working tree files would be overwritten by merge`
            #      `Please move or remove them before you merge.`.

            ret = call_git_no_except(['show-ref', '--verify', git_local_refspec_token])

            # CAUTION:
            #   1. Is required to avoid a fetch into the `master` branch by default.
            #
            if not ret[0]:
              call_git(['switch', '--no-guess', git_local_branch])
            else:
              # recreate the local branch
              git_recreate_head_branch(git_local_branch)

          # svn fetch and git push is available only on a writable (not readonly) repository
          if not fetch_state_ref['is_read_only_repo']:
            last_pushed_git_svn_commit = fetch_state_ref['last_pushed_git_svn_commit']
            last_pushed_git_svn_commit_rev = last_pushed_git_svn_commit[0]

            git_svn_fetch(git_svn_repo_tree_tuple_ref, last_pushed_git_svn_commit_rev, git_svn_fetch_cmdline_list,
              last_pruned_git_svn_commit_dict,
              prune_empty_git_svn_commits)

            # revert again if last fetch has broke the HEAD

            # get last pushed commit hash
            git_last_pushed_commit_hash = get_git_last_pushed_commit_hash(git_reporoot, git_remote_local_refspec_token)

            git_reset_if_head_is_not_last_pushed(git_last_pushed_commit_hash, git_local_refspec_token, git_remote_refspec_token,
              reset_hard = reset_hard)

          print('---')

          if parent_tuple_ref is None and root_only:
            break

def git_reset(configure_dir, scm_token, git_subtrees_root = None, root_only = False, reset_hard = False, cleanup = False, remove_svn_on_reset = False,
              update_svn_repo_uuid = False, verbosity = 0):
  print("git_reset: {0}".format(configure_dir))

  set_verbosity_level(verbosity)

  if not git_subtrees_root is None:
    print(' * git_subtrees_root: `' + git_subtrees_root + '`')

  if configure_dir == '':
    print_err("{0}: error: configure directory is not defined.".format(sys.argv[0]))
    return 1

  if configure_dir[-1:] in ['\\', '/']:
    configure_dir = configure_dir[:-1]

  if not os.path.isdir(configure_dir):
    print_err("{0}: error: configure directory does not exist: `{1}`.".format(sys.argv[0], configure_dir))
    return 32

  if not git_subtrees_root is None and not os.path.isdir(git_subtrees_root):
    print_err("{0}: error: git subtrees root directory does not exist: git_subtrees_root=`{1}`.".format(sys.argv[0], git_subtrees_root))
    return 33

  wcroot_dir = getglobalvar(scm_token + '.WCROOT_DIR')
  if wcroot_dir == '': return -254
  if WCROOT_OFFSET == '': return -253

  wcroot_path = os.path.abspath(os.path.join(WCROOT_OFFSET, wcroot_dir)).replace('\\', '/')

  git_user = getglobalvar(scm_token + '.USER')
  git_email = getglobalvar(scm_token + '.EMAIL')

  if not os.path.exists(wcroot_path):
    os.mkdir(wcroot_path)

  with local_cwd(' ->> cwd: `{0}`...', ' -<< cwd: `{0}`...', wcroot_path), \
       GitReposListReader(configure_dir + '/git_repos.lst') as git_repos_reader, ServiceProcCache() as svc_proc_cache:
    executed_procs = cache_init_service_proc(svc_proc_cache)

    with tkl.OnExit(lambda: cache_close_running_procs(executed_procs, svc_proc_cache)):
      column_names, column_widths = get_git_svn_repos_list_table_params()

      if git_subtrees_root is None:
        git_subtrees_root = wcroot_path + '/.git/.pyxvcs/gitwc'

      git_svn_repo_tree_dict, git_svn_repo_tree_tuple_ref_preorder_list, svn_repo_root_to_uuid_dict, git_svn_params_dict = \
        read_git_svn_repo_list(git_repos_reader, scm_token, wcroot_path, git_subtrees_root, column_names, column_widths,
          update_svn_repo_uuid = update_svn_repo_uuid)

      print('- GIT switching...')

      for git_svn_repo_tree_tuple_ref in git_svn_repo_tree_tuple_ref_preorder_list:
        repo_params_ref = git_svn_repo_tree_tuple_ref[0]

        parent_tuple_ref = repo_params_ref['parent_tuple_ref']

        ordinal_index_prefix_str = repo_params_ref['ordinal_index_prefix_str']

        remote_name = repo_params_ref['remote_name']

        git_reporoot = repo_params_ref['git_reporoot']

        parent_git_path_prefix = repo_params_ref['parent_git_path_prefix']

        git_local_branch = repo_params_ref['git_local_branch']
        git_remote_branch = repo_params_ref['git_remote_branch']

        if not parent_tuple_ref is None:
          subtree_git_wcroot = repo_params_ref['git_wcroot']

        with conditional(not parent_tuple_ref is None,
                         local_cwd(' ->> cwd: `{0}`...', ' -<< cwd: `{0}`...', subtree_git_wcroot) if not parent_tuple_ref is None else None):
          git_remote_refspec_token, git_remote_local_refspec_token = \
            get_git_remote_refspec_token_tuple(remote_name, git_local_branch, git_remote_branch)

          # get last pushed commit hash
          git_last_pushed_commit_hash = get_git_last_pushed_commit_hash(git_reporoot, git_remote_local_refspec_token)

          git_local_refspec_token = get_git_local_refspec_token(git_local_branch, git_remote_branch)

          # CAUTION:
          #   1. The index file cleanup is required here to avoid the error messsage:
          #      `fatal: cannot switch branch while merging`
          #   2. The Working Copy cleanup is required together with the index file cleanup to avoid later a problem with a
          #      merge around untracked files with the error message:
          #      `error: The following untracked working tree files would be overwritten by merge`
          #      `Please move or remove them before you merge.`.
          #   3. We have to cleanup the HEAD instead of the local branch.
          #
          if reset_hard:
            call_git(['reset', '--hard'])
          else:
            call_git(['reset', '--mixed'])

          # cleanup the untracked files if were left behind, for example, by the previous `git reset --mixed`
          if cleanup:
            call_git(['clean', '-d', '-f'])

          ret = call_git_no_except(['show-ref', '--verify', git_local_refspec_token])

          # CAUTION:
          #   1. Is required to avoid a fetch into the `master` branch by default.
          #
          if not ret[0]:
            call_git(['switch', '--no-guess', git_local_branch])
          else:
            # recreate the local branch
            git_recreate_head_branch(git_local_branch)

          print('---')

          if parent_tuple_ref is None and root_only:
            break

      print('- GIT resetting...')

      for git_svn_repo_tree_tuple_ref in git_svn_repo_tree_tuple_ref_preorder_list:
        repo_params_ref = git_svn_repo_tree_tuple_ref[0]

        parent_tuple_ref = repo_params_ref['parent_tuple_ref']
        children_tuple_ref_list = repo_params_ref['children_tuple_ref_list']

        ordinal_index_prefix_str = repo_params_ref['ordinal_index_prefix_str']

        remote_name = repo_params_ref['remote_name']

        git_reporoot = repo_params_ref['git_reporoot']

        parent_git_path_prefix = repo_params_ref['parent_git_path_prefix']

        git_local_branch = repo_params_ref['git_local_branch']
        git_remote_branch = repo_params_ref['git_remote_branch']

        if not parent_tuple_ref is None:
          subtree_git_wcroot = repo_params_ref['git_wcroot']

        with conditional(not parent_tuple_ref is None,
                         local_cwd(' ->> cwd: `{0}`...', ' -<< cwd: `{0}`...', subtree_git_wcroot) if not parent_tuple_ref is None else None):
          git_remote_refspec_token, git_remote_local_refspec_token = \
            get_git_remote_refspec_token_tuple(remote_name, git_local_branch, git_remote_branch)

          # get last pushed commit hash
          git_last_pushed_commit_hash = get_git_last_pushed_commit_hash(git_reporoot, git_remote_local_refspec_token)

          # 1. compare the last pushed commit hash with the last fetched commit hash and if different, then revert FETCH_HEAD
          # 2. additionally, compare the last pushed commit hash with the head commit hash and if different then revert HEAD

          git_local_refspec_token = get_git_local_refspec_token(git_local_branch, git_remote_branch)

          git_reset_if_head_is_not_last_pushed(git_last_pushed_commit_hash, git_local_refspec_token, git_remote_refspec_token,
            reset_hard = reset_hard)

          # remove all subtree merge branches
          git_remove_child_subtree_merge_branches(children_tuple_ref_list)

          print('---')

          if parent_tuple_ref is None and root_only:
            break

      print('- GIT-SVN resetting...')

      for git_svn_repo_tree_tuple_ref in git_svn_repo_tree_tuple_ref_preorder_list:
        repo_params_ref = git_svn_repo_tree_tuple_ref[0]

        parent_tuple_ref = repo_params_ref['parent_tuple_ref']

        ordinal_index_prefix_str = repo_params_ref['ordinal_index_prefix_str']

        remote_name = repo_params_ref['remote_name']

        git_local_branch = repo_params_ref['git_local_branch']

        parent_git_path_prefix = repo_params_ref['parent_git_path_prefix']

        if not parent_tuple_ref is None:
          subtree_git_wcroot = repo_params_ref['git_wcroot']

        with conditional(not parent_tuple_ref is None,
                         local_cwd(' ->> cwd: `{0}`...', ' -<< cwd: `{0}`...', subtree_git_wcroot) if not parent_tuple_ref is None else None):
          if remove_svn_on_reset:
            git_svn_trunk_remote_refspec_shorted_token = get_git_svn_trunk_remote_refspec_token(remote_name, shorted = True)
            git_svn_trunk_remote_refspec_token = get_git_svn_trunk_remote_refspec_token(remote_name)

            git_remove_svn_branch(git_svn_trunk_remote_refspec_shorted_token, git_svn_trunk_remote_refspec_token)

          git_cleanup_local_branch(remote_name, git_local_branch, git_local_refspec_token)

          print('---')

          if parent_tuple_ref is None and root_only:
            break

def git_pull(configure_dir, scm_token, git_subtrees_root = None, root_only = False, reset_hard = False, prune_empty_git_svn_commits = True,
             update_svn_repo_uuid = False, verbosity = 0):
  print("git_pull: {0}".format(configure_dir))

  set_verbosity_level(verbosity)

  if not git_subtrees_root is None:
    print(' * git_subtrees_root: `' + git_subtrees_root + '`')

  if configure_dir == '':
    print_err("{0}: error: configure directory is not defined.".format(sys.argv[0]))
    return 1

  if configure_dir[-1:] in ['\\', '/']:
    configure_dir = configure_dir[:-1]

  if not os.path.isdir(configure_dir):
    print_err("{0}: error: configure directory does not exist: `{1}`.".format(sys.argv[0], configure_dir))
    return 32

  if not git_subtrees_root is None and not os.path.isdir(git_subtrees_root):
    print_err("{0}: error: git subtrees root directory does not exist: git_subtrees_root=`{1}`.".format(sys.argv[0], git_subtrees_root))
    return 33

  wcroot_dir = getglobalvar(scm_token + '.WCROOT_DIR')
  if wcroot_dir == '': return -254
  if WCROOT_OFFSET == '': return -253

  wcroot_path = os.path.abspath(os.path.join(WCROOT_OFFSET, wcroot_dir)).replace('\\', '/')

  git_user = getglobalvar(scm_token + '.USER')
  git_email = getglobalvar(scm_token + '.EMAIL')

  if not os.path.exists(wcroot_path):
    os.mkdir(wcroot_path)

  max_time_depth_in_multiple_svn_commits_fetch_sec = get_max_time_depth_in_multiple_svn_commits_fetch_sec()

  with local_cwd(' ->> cwd: `{0}`...', ' -<< cwd: `{0}`...', wcroot_path), \
       GitReposListReader(configure_dir + '/git_repos.lst') as git_repos_reader, ServiceProcCache() as svc_proc_cache:
    executed_procs = cache_init_service_proc(svc_proc_cache)

    with tkl.OnExit(lambda: cache_close_running_procs(executed_procs, svc_proc_cache)):
      column_names, column_widths = get_git_svn_repos_list_table_params()

      if git_subtrees_root is None:
        git_subtrees_root = wcroot_path + '/.git/.pyxvcs/gitwc'

      git_svn_repo_tree_dict, git_svn_repo_tree_tuple_ref_preorder_list, svn_repo_root_to_uuid_dict, git_svn_params_dict = \
        read_git_svn_repo_list(git_repos_reader, scm_token, wcroot_path, git_subtrees_root, column_names, column_widths,
          update_svn_repo_uuid = update_svn_repo_uuid)

      print('- GIT switching...')

      for git_svn_repo_tree_tuple_ref in git_svn_repo_tree_tuple_ref_preorder_list:
        repo_params_ref = git_svn_repo_tree_tuple_ref[0]

        parent_tuple_ref = repo_params_ref['parent_tuple_ref']

        ordinal_index_prefix_str = repo_params_ref['ordinal_index_prefix_str']

        remote_name = repo_params_ref['remote_name']

        git_reporoot = repo_params_ref['git_reporoot']

        parent_git_path_prefix = repo_params_ref['parent_git_path_prefix']

        git_local_branch = repo_params_ref['git_local_branch']
        git_remote_branch = repo_params_ref['git_remote_branch']

        if not parent_tuple_ref is None:
          subtree_git_wcroot = repo_params_ref['git_wcroot']

        with conditional(not parent_tuple_ref is None,
                         local_cwd(' ->> cwd: `{0}`...', ' -<< cwd: `{0}`...', subtree_git_wcroot) if not parent_tuple_ref is None else None):
          git_remote_refspec_token, git_remote_local_refspec_token = \
            get_git_remote_refspec_token_tuple(remote_name, git_local_branch, git_remote_branch)

          # get last pushed commit hash
          git_last_pushed_commit_hash = get_git_last_pushed_commit_hash(git_reporoot, git_remote_local_refspec_token)

          if not git_last_pushed_commit_hash is None:
            # CAUTION:
            #   1. The index file cleanup might be required here to avoid the error messsage:
            #      `fatal: cannot switch branch while merging`
            #   2. The Working Copy cleanup is required together with the index file cleanup to avoid later a problem with a
            #      merge around untracked files with the error message:
            #      `error: The following untracked working tree files would be overwritten by merge`
            #      `Please move or remove them before you merge.`.

            git_local_refspec_token = get_git_local_refspec_token(git_local_branch, git_remote_branch)

            ret = call_git_no_except(['show-ref', '--verify', git_local_refspec_token])

            # CAUTION:
            #   1. Is required to avoid a fetch into the `master` branch by default.
            #
            if not ret[0]:
              call_git(['switch', '--no-guess', git_local_branch])
            else:
              # recreate the local branch
              git_recreate_head_branch(git_local_branch)

          print('---')

          if parent_tuple_ref is None and root_only:
            break

      print('- GIT fetching...')

      for git_svn_repo_tree_tuple_ref in git_svn_repo_tree_tuple_ref_preorder_list:
        repo_params_ref = git_svn_repo_tree_tuple_ref[0]

        parent_tuple_ref = repo_params_ref['parent_tuple_ref']

        ordinal_index_prefix_str = repo_params_ref['ordinal_index_prefix_str']

        remote_name = repo_params_ref['remote_name']
        parent_remote_name = repo_params_ref['parent_remote_name']

        git_reporoot = repo_params_ref['git_reporoot']

        parent_git_path_prefix = repo_params_ref['parent_git_path_prefix']

        git_local_branch = repo_params_ref['git_local_branch']
        git_remote_branch = repo_params_ref['git_remote_branch']

        if not parent_tuple_ref is None:
          subtree_git_wcroot = repo_params_ref['git_wcroot']

        with conditional(not parent_tuple_ref is None,
                         local_cwd(' ->> cwd: `{0}`...', ' -<< cwd: `{0}`...', subtree_git_wcroot) if not parent_tuple_ref is None else None):
          git_remote_refspec_token, git_remote_local_refspec_token = \
            get_git_remote_refspec_token_tuple(remote_name, git_local_branch, git_remote_branch)

          # get last pushed commit hash
          git_last_pushed_commit_hash = get_git_last_pushed_commit_hash(git_reporoot, git_remote_local_refspec_token)

          if not git_last_pushed_commit_hash is None:
            git_fetch_refspec_token = get_git_fetch_refspec_token(git_local_branch, git_remote_branch)

            call_git(['fetch', remote_name, git_fetch_refspec_token])

          # 1. compare the last pushed commit hash with the last fetched commit hash and if different, then revert FETCH_HEAD
          # 2. additionally, compare the last pushed commit hash with the head commit hash and if different then revert HEAD

          git_local_refspec_token = get_git_local_refspec_token(git_local_branch, git_remote_branch)

          git_reset_if_head_is_not_last_pushed(git_last_pushed_commit_hash, git_local_refspec_token, git_remote_refspec_token,
            reset_hard = reset_hard)

          print('---')

          if parent_tuple_ref is None and root_only:
            break

      update_git_svn_repo_fetch_state(git_svn_repo_tree_tuple_ref_preorder_list, git_svn_params_dict,
        max_time_depth_in_multiple_svn_commits_fetch_sec, root_only = root_only, is_first_time_update = True)

      print('- GIT-SVN fetching...')

      for git_svn_repo_tree_tuple_ref in git_svn_repo_tree_tuple_ref_preorder_list:
        repo_params_ref = git_svn_repo_tree_tuple_ref[0]
        fetch_state_ref = git_svn_repo_tree_tuple_ref[1]

        parent_tuple_ref = repo_params_ref['parent_tuple_ref']

        ordinal_index_prefix_str = repo_params_ref['ordinal_index_prefix_str']

        remote_name = repo_params_ref['remote_name']

        git_reporoot = repo_params_ref['git_reporoot']
        svn_reporoot = repo_params_ref['svn_reporoot']

        parent_git_path_prefix = repo_params_ref['parent_git_path_prefix']

        git_local_branch = repo_params_ref['git_local_branch']
        git_remote_branch = repo_params_ref['git_remote_branch']

        git_svn_fetch_ignore_paths_regex = repo_params_ref['git_ignore_paths_regex']

        if not parent_tuple_ref is None:
          subtree_git_wcroot = repo_params_ref['git_wcroot']

        with conditional(not parent_tuple_ref is None,
                         local_cwd(' ->> cwd: `{0}`...', ' -<< cwd: `{0}`...', subtree_git_wcroot) if not parent_tuple_ref is None else None):
          last_pruned_git_svn_commit_dict = fetch_state_ref['last_pruned_git_svn_commit_dict']

          git_svn_fetch_cmdline_list = []

          if len(git_svn_fetch_ignore_paths_regex) > 0:
            git_svn_fetch_cmdline_list.append('--ignore-paths=' + git_svn_fetch_ignore_paths_regex)

          # git-svn (re)fetch next svn revision

          git_local_refspec_token = get_git_local_refspec_token(git_local_branch, git_remote_branch)
          git_remote_refspec_token, git_remote_local_refspec_token = \
            get_git_remote_refspec_token_tuple(remote_name, git_local_branch, git_remote_branch)

          # get last pushed commit hash
          git_last_pushed_commit_hash = get_git_last_pushed_commit_hash(git_reporoot, git_remote_local_refspec_token)

          if not git_last_pushed_commit_hash is None:
            ret = call_git_no_except(['show-ref', '--verify', git_local_refspec_token])

            # CAUTION:
            #   1. Is required to avoid a fetch into the `master` branch by default.
            #
            if not ret[0]:
              call_git(['switch', '--no-guess', git_local_branch])
            else:
              # recreate the local branch
              git_recreate_head_branch(git_local_branch)

          # svn fetch and git push is available only on a writable (not readonly) repository
          if not fetch_state_ref['is_read_only_repo']:
            last_pushed_git_svn_commit = fetch_state_ref['last_pushed_git_svn_commit']
            last_pushed_git_svn_commit_rev = last_pushed_git_svn_commit[0]

            git_svn_fetch(git_svn_repo_tree_tuple_ref, last_pushed_git_svn_commit_rev, git_svn_fetch_cmdline_list,
              last_pruned_git_svn_commit_dict,
              prune_empty_git_svn_commits)

            # revert again if last fetch has broke the HEAD

            # get last pushed commit hash
            git_last_pushed_commit_hash = get_git_last_pushed_commit_hash(git_reporoot, git_remote_local_refspec_token)

            git_reset_if_head_is_not_last_pushed(git_last_pushed_commit_hash, git_local_refspec_token, git_remote_refspec_token,
              reset_hard = reset_hard)

          print('---')

          if parent_tuple_ref is None and root_only:
            break

      print('- GIT checkouting...')

      for git_svn_repo_tree_tuple_ref in git_svn_repo_tree_tuple_ref_preorder_list:
        repo_params_ref = git_svn_repo_tree_tuple_ref[0]

        parent_tuple_ref = repo_params_ref['parent_tuple_ref']

        ordinal_index_prefix_str = repo_params_ref['ordinal_index_prefix_str']

        remote_name = repo_params_ref['remote_name']

        parent_git_path_prefix = repo_params_ref['parent_git_path_prefix']

        git_local_branch = repo_params_ref['git_local_branch']
        git_remote_branch = repo_params_ref['git_remote_branch']

        if not parent_tuple_ref is None:
          subtree_git_wcroot = repo_params_ref['git_wcroot']

        with conditional(not parent_tuple_ref is None,
                         local_cwd(' ->> cwd: `{0}`...', ' -<< cwd: `{0}`...', subtree_git_wcroot) if not parent_tuple_ref is None else None):
          git_local_refspec_token = get_git_local_refspec_token(git_local_branch, git_remote_branch)

          ret = call_git_no_except(['show-ref', '--verify', git_local_refspec_token])

          # CAUTION:
          #   1. Is required to avoid a fetch into the `master` branch by default.
          #
          if not ret[0]:
            call_git(['switch', '--no-guess', git_local_branch])

            # CAUTION:
            #   The HEAD reference still can be not initialized after the `git switch ...` command.
            #   We have to try to initialize it from here.
            #
            call_git(['checkout', '--no-guess', git_local_branch])
          else:
            # recreate the local branch
            git_recreate_head_branch(git_local_branch)

          print('---')

          if parent_tuple_ref is None and root_only:
            break

def collect_notpushed_svn_revisions_ordered_by_timestamp(git_svn_repo_tree_tuple_ref_preorder_list):
  print('- Collecting not pushed svn commits:')

  notpushed_svn_commit_by_timestamp_dict = {}

  for git_svn_repo_tree_tuple_ref in reversed(git_svn_repo_tree_tuple_ref_preorder_list): # in reverse
    fetch_state_ref = git_svn_repo_tree_tuple_ref[1]

    min_tree_time_of_last_notpushed_svn_commit = fetch_state_ref['min_tree_time_of_last_notpushed_svn_commit']
    min_ro_tree_time_of_first_notpushed_svn_commit = fetch_state_ref['min_ro_tree_time_of_first_notpushed_svn_commit']

    notpushed_svn_commit_list = fetch_state_ref['notpushed_svn_commit_list']
    if not notpushed_svn_commit_list is None:
      for notpushed_svn_commit in notpushed_svn_commit_list:
        notpushed_svn_commit_timestamp = notpushed_svn_commit[2]
        if not min_tree_time_of_last_notpushed_svn_commit is None and \
           notpushed_svn_commit_timestamp > min_tree_time_of_last_notpushed_svn_commit[0]:
          break

        notpushed_svn_commit_by_timestamp = notpushed_svn_commit_by_timestamp_dict.get(notpushed_svn_commit_timestamp)
        if not notpushed_svn_commit_by_timestamp is None:
          # append to the end, because repos already being traversed in reverse order to the tree preorder traversal
          notpushed_svn_commit_by_timestamp.append((notpushed_svn_commit[0], notpushed_svn_commit[3], git_svn_repo_tree_tuple_ref))
        else:
          notpushed_svn_commit_by_timestamp_dict[notpushed_svn_commit_timestamp] = \
            [(notpushed_svn_commit[0], notpushed_svn_commit[3], git_svn_repo_tree_tuple_ref)]

        if not min_ro_tree_time_of_first_notpushed_svn_commit is None and \
           notpushed_svn_commit_timestamp >= min_ro_tree_time_of_first_notpushed_svn_commit[0]:
          break

  min_tree_time_of_last_notpushed_svn_commit = get_root_min_tree_time_of_last_notpushed_svn_commit(git_svn_repo_tree_tuple_ref_preorder_list)
  min_tree_time_of_last_notpushed_svn_commit_timestamp = min_tree_time_of_last_notpushed_svn_commit[0]

  column_fmt_str = '{:<{}} {:<{}} {:<{}} {:<{}}'
  column_names = ['<svn_timestamp_date_time>', '<rev>', '<remote_name>', '<svn_repopath>']
  column_widths = [43, 9, 20, 64]

  git_print_repos_list_header(column_names, column_widths, column_fmt_str)

  for notpushed_svn_commit_timestamp, notpushed_svn_commit_list in sorted(notpushed_svn_commit_by_timestamp_dict.items()):
    for notpushed_svn_commit_tuple in notpushed_svn_commit_list:
      notpushed_svn_commit_rev = notpushed_svn_commit_tuple[0]
      notpushed_svn_commit_date_time = notpushed_svn_commit_tuple[1]
      notpushed_svn_commit_git_svn_repo_tree_tuple_ref = notpushed_svn_commit_tuple[2]

      repo_params_ref = notpushed_svn_commit_git_svn_repo_tree_tuple_ref[0]
      fetch_state_ref = notpushed_svn_commit_git_svn_repo_tree_tuple_ref[1]

      nest_index = repo_params_ref['nest_index']
      remote_name = repo_params_ref['remote_name']
      svn_reporoot = repo_params_ref['svn_reporoot']
      svn_path_prefix = repo_params_ref['svn_path_prefix']

      svn_repopath = svn_reporoot + (('/' + svn_path_prefix) if svn_path_prefix != '' else '')

      is_read_only_repo = fetch_state_ref['is_read_only_repo']

      if not is_read_only_repo:
        row_values = [('* ' if notpushed_svn_commit_timestamp == min_tree_time_of_last_notpushed_svn_commit_timestamp else '  ') + \
          str(notpushed_svn_commit_timestamp) + ' {' + notpushed_svn_commit_tuple[1] + '}',
          'r' + str(notpushed_svn_commit_tuple[0]), ('| ' * nest_index) + remote_name, svn_repopath]
      else:
        row_values = ['o ' + \
          str(notpushed_svn_commit_timestamp) + ' {' + notpushed_svn_commit_tuple[1] + '}',
          'r' + str(notpushed_svn_commit_tuple[0]), ('| ' * nest_index) + remote_name, svn_repopath]
      git_print_repos_list_row(row_values, column_widths, column_fmt_str)

  git_print_repos_list_footer(column_widths)

  print_root_min_tree_time_of_last_notpushed_svn_commit('  * -', git_svn_repo_tree_tuple_ref_preorder_list)
  print_root_min_ro_tree_time_of_first_notpushed_svn_commit('  o -', git_svn_repo_tree_tuple_ref_preorder_list)

  return notpushed_svn_commit_by_timestamp_dict

def collect_last_pushed_git_svn_commits_by_max_author_timestamp(git_svn_repo_tree_tuple_ref_preorder_list):
  last_pushed_git_svn_commits_by_last_timestamp_list = []
  last_pushed_git_svn_commit_max_author_timestamp = 0

  for git_svn_repo_tree_tuple_ref in git_svn_repo_tree_tuple_ref_preorder_list:
    fetch_state_ref = git_svn_repo_tree_tuple_ref[1]

    last_pushed_git_svn_commit = fetch_state_ref['last_pushed_git_svn_commit']
    last_pushed_git_svn_commit_rev = last_pushed_git_svn_commit[0]
    if last_pushed_git_svn_commit_rev > 0:
      last_pushed_git_svn_commit_author_timestamp = last_pushed_git_svn_commit[2]
      if last_pushed_git_svn_commit_max_author_timestamp < last_pushed_git_svn_commit_author_timestamp:
        last_pushed_git_svn_commit_max_author_timestamp = last_pushed_git_svn_commit_author_timestamp
        # reset the list
        last_pushed_git_svn_commits_by_last_timestamp_list = [git_svn_repo_tree_tuple_ref]
      elif last_pushed_git_svn_commit_max_author_timestamp == last_pushed_git_svn_commit_author_timestamp:
        last_pushed_git_svn_commits_by_last_timestamp_list.append(git_svn_repo_tree_tuple_ref)

  return (last_pushed_git_svn_commits_by_last_timestamp_list, last_pushed_git_svn_commit_max_author_timestamp)

def remove_git_svn_tree_direct_descendants_from_list(git_svn_repo_tree_tuple_ref_commits_list):
  filtered_git_svn_repo_tree_tuple_ref_commits_list = []

  for git_svn_repo_tree_tuple_ref in git_svn_repo_tree_tuple_ref_commits_list:
    repo_params_ref = git_svn_repo_tree_tuple_ref[0]

    is_direct_descendant = False
    nest_lvl = 0

    parent_tuple_ref = repo_params_ref['parent_tuple_ref']

    while not parent_tuple_ref is None:
      if parent_tuple_ref in git_svn_repo_tree_tuple_ref_commits_list:
        if nest_lvl > 0:
          raise Exception('fetch-merge-push sequence is corrupted, the list must contain only direct descendants!')
        is_direct_descendant = True
        break

      parent_repo_params_ref = parent_tuple_ref[0]
      parent_tuple_ref = parent_repo_params_ref['parent_tuple_ref']
      nest_lvl += 1

    if is_direct_descendant:
      continue

    # not found
    filtered_git_svn_repo_tree_tuple_ref_commits_list.append(git_svn_repo_tree_tuple_ref)

  return filtered_git_svn_repo_tree_tuple_ref_commits_list if len(filtered_git_svn_repo_tree_tuple_ref_commits_list) > 0 else None

def if_git_svn_commit_is_ancestor_to_commits_in_list(git_svn_tuple_ref_to_check, git_svn_tuple_ref_list):
  for git_svn_tuple_ref in git_svn_tuple_ref_list:
    repo_params_ref = git_svn_tuple_ref[0]
    parent_tuple_ref = repo_params_ref['parent_tuple_ref']

    while not parent_tuple_ref is None:
      if git_svn_tuple_ref_to_check is parent_tuple_ref:
        return True

      parent_repo_params_ref = parent_tuple_ref[0]
      parent_tuple_ref = parent_repo_params_ref['parent_tuple_ref']

  return False

def git_check_if_parent_child_in_ahead_behind_state(*args, **kwargs):
  print('- Checking parent/child on ahead/behind state:')

  return _git_check_if_parent_child_in_ahead_behind_state_impl(*args, **kwargs)

def _git_check_if_parent_child_in_ahead_behind_state_impl(parent_tuple_ref, child_tuple_ref = None, recursively = False):
  # 1. A parent repository should not be ahead at any pushed commits versus the first not pushed commit from any child repository.
  # 2. A writable child repository should not be ahead at any pushed commits versus the first not pushed commit from any parent repository.
  # 3. A readonly child repository can be ahead at any pushed commits versus the first not pushed commit from any parent repository.

  parent_repo_params_ref = parent_tuple_ref[0]
  parent_fetch_state_ref = parent_tuple_ref[1]

  if not child_tuple_ref is None:
    children_tuple_ref_list = [child_tuple_ref]
  else:
    children_tuple_ref_list = parent_repo_params_ref['children_tuple_ref_list']
    if not len(children_tuple_ref_list) > 0:
      return

  parent_nest_index = parent_repo_params_ref['nest_index']

  parent_remote_name = parent_repo_params_ref['remote_name']
  parent_svn_reporoot = parent_repo_params_ref['svn_reporoot']

  parent_git_local_branch = parent_repo_params_ref['git_local_branch']
  parent_git_remote_branch = parent_repo_params_ref['git_remote_branch']

  parent__git_path_prefix = parent_repo_params_ref['git_path_prefix']
  parent_svn_path_prefix = parent_repo_params_ref['svn_path_prefix']

  parent_notpushed_svn_commit_list = parent_fetch_state_ref['notpushed_svn_commit_list']

  parent_git_wcroot = parent_repo_params_ref['git_wcroot']

  parent_svn_repopath = parent_svn_reporoot + (('/' + parent_svn_path_prefix) if parent_svn_path_prefix != '' else '')

  print('  ' + ('| ' * parent_nest_index) + parent_remote_name + ' <-> [' + ', '.join([child_tuple_ref[0]['remote_name'] for child_tuple_ref in children_tuple_ref_list]) + ']')

  column_names, column_widths = get_git_svn_repos_list_table_params()

  for child_tuple_ref in children_tuple_ref_list:
    parent_last_pushed_git_svn_commit = parent_fetch_state_ref['last_pushed_git_svn_commit']
    parent_last_pushed_git_svn_commit_author_timestamp = parent_last_pushed_git_svn_commit[2]
    parent_last_pushed_git_svn_commit_author_date_time = parent_last_pushed_git_svn_commit[3]

    child_repo_params_ref = child_tuple_ref[0]
    child_fetch_state_ref = child_tuple_ref[1]

    child_notpushed_svn_commit_list = child_fetch_state_ref['notpushed_svn_commit_list']

    # 1.
    #

    # any child git repository should not be behind the parent git repository irrespective to an svn repository uuid
    if not parent_last_pushed_git_svn_commit_author_timestamp is None and not child_notpushed_svn_commit_list is None and len(child_notpushed_svn_commit_list) > 0:
      child_first_notpushed_svn_commit = child_notpushed_svn_commit_list[0]
      child_first_notpushed_svn_commit_timestamp = child_first_notpushed_svn_commit[2]
      child_first_notpushed_svn_commit_date_time = child_first_notpushed_svn_commit[3]

      if parent_last_pushed_git_svn_commit_author_timestamp >= child_first_notpushed_svn_commit_timestamp:
        child_remote_name = child_repo_params_ref['remote_name']

        print('  The parent GIT repository `' + parent_remote_name + '` is ahead to the child GIT repository `' + child_remote_name + '`:')

        child_svn_reporoot = child_repo_params_ref['svn_reporoot']
        child_svn_path_prefix = child_repo_params_ref['svn_path_prefix']

        child_svn_repopath = child_svn_reporoot + (('/' + child_svn_path_prefix) if child_svn_path_prefix != '' else '')

        git_print_repos_list_header(column_names, column_widths)

        row_values = [
          parent_remote_name, parent_repo_params_ref['git_reporoot'], parent_repo_params_ref['parent_git_path_prefix'],
          parent_svn_repopath, parent_git_local_branch, parent_git_remote_branch
        ]
        git_print_repos_list_row(row_values, column_widths)

        row_values = [
          '| ' + child_repo_params_ref['remote_name'], child_repo_params_ref['git_reporoot'], child_repo_params_ref['parent_git_path_prefix'],
          child_svn_repopath, child_repo_params_ref['git_local_branch'], child_repo_params_ref['git_remote_branch']
        ]
        git_print_repos_list_row(row_values, column_widths)

        git_print_repos_list_footer(column_widths)

        print('    parent_last_pushed_git_svn_commit: ' + str(parent_last_pushed_git_svn_commit_author_timestamp) + ' {' + parent_last_pushed_git_svn_commit_author_date_time + '}')
        print('    child_first_notpushed_svn_commit:  ' + str(child_first_notpushed_svn_commit_timestamp) + ' {' + child_first_notpushed_svn_commit_date_time + '}')

        print('  These has been pushed commits of the parent GIT repository are ahead to the child repository and they must be unpushed back before continue:')

        with conditional(parent_git_wcroot != '.',
                         local_cwd(' ->> cwd: `{0}`...', ' -<< cwd: `{0}`...', parent_git_wcroot)):
          call_git(['log', '--format=' + get_default_git_log_format(),
            get_git_remote_refspec_token(parent_remote_name, parent_git_local_branch, parent_git_remote_branch),
            '--since', str(child_first_notpushed_svn_commit_timestamp)] +
            (['--', parent__git_path_prefix] if parent__git_path_prefix != '' else []),
            max_stdout_lines = 32)

        raise Exception('the parent GIT repository `' + parent_remote_name + '` is ahead to the child GIT repository `' + child_remote_name + '`')

    # 2.
    #

    if not child_fetch_state_ref['is_read_only_repo']:
      child_last_pushed_git_svn_commit = child_fetch_state_ref['last_pushed_git_svn_commit']
      child_last_pushed_git_svn_author_timestamp = child_last_pushed_git_svn_commit[2]
      child_last_pushed_git_svn_author_date_time = child_last_pushed_git_svn_commit[3]

      if not child_last_pushed_git_svn_author_timestamp is None and not parent_notpushed_svn_commit_list is None and len(parent_notpushed_svn_commit_list) > 0:
        parent_first_notpushed_svn_commit = parent_notpushed_svn_commit_list[0]
        parent_first_notpushed_svn_commit_timestamp = parent_first_notpushed_svn_commit[2]
        parent_first_notpushed_svn_commit_date_time = parent_first_notpushed_svn_commit[3]

        if parent_first_notpushed_svn_commit_timestamp <= child_last_pushed_git_svn_author_timestamp:
          child_remote_name = child_repo_params_ref['remote_name']

          print('  The child GIT repository `' + child_remote_name + '` is ahead to the parent GIT repository `' + parent_remote_name + '`:')

          child_svn_reporoot = child_repo_params_ref['svn_reporoot']

          child_git_local_branch = child_repo_params_ref['git_local_branch']
          child_git_remote_branch = child_repo_params_ref['git_remote_branch']

          child__git_path_prefix = child_repo_params_ref['git_path_prefix']
          child_svn_path_prefix = child_repo_params_ref['svn_path_prefix']

          child_svn_repopath = child_svn_reporoot + (('/' + child_svn_path_prefix) if child_svn_path_prefix != '' else '')

          git_print_repos_list_header(column_names, column_widths)

          row_values = [
            parent_repo_params_ref['remote_name'], parent_repo_params_ref['git_reporoot'], parent_repo_params_ref['parent_git_path_prefix'],
            parent_svn_repopath, parent_repo_params_ref['git_local_branch'], parent_repo_params_ref['git_remote_branch']
          ]
          git_print_repos_list_row(row_values, column_widths)

          row_values = [
            '| ' + child_remote_name, child_repo_params_ref['git_reporoot'], child_repo_params_ref['parent_git_path_prefix'],
            child_svn_repopath, child_git_local_branch, child_git_remote_branch
          ]
          git_print_repos_list_row(row_values, column_widths)

          git_print_repos_list_footer(column_widths)

          print('    parent_first_notpushed_svn_commit: ' + str(parent_first_notpushed_svn_commit_timestamp) + ' {' + parent_first_notpushed_svn_commit_date_time + '}')
          print('    child_last_pushed_git_svn_commit:  ' + str(child_last_pushed_git_svn_author_timestamp) + ' {' + child_last_pushed_git_svn_author_date_time + '}')

          print('  These has been pushed commits of the child GIT repository are ahead to the parent repository and they must be unpushed back before continue:')

          child_git_wcroot = child_repo_params_ref['git_wcroot']

          with conditional(child_git_wcroot != '.',
                           local_cwd(' ->> cwd: `{0}`...', ' -<< cwd: `{0}`...', child_git_wcroot)):
            call_git(['log', '--format=' + get_default_git_log_format(),
              get_git_remote_refspec_token(child_remote_name, child_git_local_branch, child_git_remote_branch),
              '--since', str(parent_first_notpushed_svn_commit_timestamp)] +
              (['--', child__git_path_prefix] if child__git_path_prefix != '' else []),
              max_stdout_lines = 32)

          raise Exception('the child GIT repository `' + child_remote_name + '` is ahead to the parent GIT repository `' + parent_remote_name + '`')

    if recursively:
      _git_check_if_parent_child_in_ahead_behind_state_impl(child_tuple_ref, recursively = True)

def advance_svn_notpushed_commits_list(git_svn_repo_tree_tuple_ref, svn_commit_rev):
  fetch_state_ref = git_svn_repo_tree_tuple_ref[1]

  first_advanced_notpushed_svn_commit = fetch_state_ref['first_advanced_notpushed_svn_commit']
  notpushed_svn_commit_list = fetch_state_ref['notpushed_svn_commit_list']

  if len(notpushed_svn_commit_list) > 0:
    first_advanced_notpushed_svn_commit = notpushed_svn_commit_list[0]

    while len(notpushed_svn_commit_list) > 0:
      notpushed_svn_commit_tuple = notpushed_svn_commit_list[0]
      notpushed_svn_commit_rev = notpushed_svn_commit_tuple[0]
      if svn_commit_rev < notpushed_svn_commit_rev:
        break
      notpushed_svn_commit_list.pop(0)

# CAUTION:
#   * The function always does process the root repository together along with the subtree repositories, because
#     it is a part of a whole 1-way synchronization process between the SVN and the GIT.
#     If you want to reduce the depth or change the configuration of subtrees, you have to edit the respective
#     `git_repos.lst` file.
#     If you want to process subtree repositories by a custom (not builtin) path,
#     then do use the `git_subtrees_root` argument as a root path to the subtree directories.
#
def git_push_from_svn(configure_dir, scm_token, git_subtrees_root = None, reset_hard = False,
                      prune_empty_git_svn_commits = True, retain_commit_git_svn_parents = False, verbosity = 0,
                      disable_parent_child_ahead_behind_check = False):
  print(">git_push_from_svn: {0}".format(configure_dir))

  set_verbosity_level(verbosity)

  if not git_subtrees_root is None:
    print(' * git_subtrees_root: `' + git_subtrees_root + '`')

  if configure_dir == '':
    print_err("{0}: error: configure directory is not defined.".format(sys.argv[0]))
    return 1

  if configure_dir[-1:] in ['\\', '/']:
    configure_dir = configure_dir[:-1]

  if not os.path.isdir(configure_dir):
    print_err("{0}: error: configure directory does not exist: `{1}`.".format(sys.argv[0], configure_dir))
    return 32

  if not git_subtrees_root is None and not os.path.isdir(git_subtrees_root):
    print_err("{0}: error: git subtrees root directory does not exist: git_subtrees_root=`{1}`.".format(sys.argv[0], git_subtrees_root))
    return 33

  wcroot_dir = getglobalvar(scm_token + '.WCROOT_DIR')
  if wcroot_dir == '': return -254
  if WCROOT_OFFSET == '': return -253

  wcroot_path = os.path.abspath(os.path.join(WCROOT_OFFSET, wcroot_dir)).replace('\\', '/')

  git_user = getglobalvar(scm_token + '.USER')
  git_email = getglobalvar(scm_token + '.EMAIL')

  if not os.path.exists(wcroot_path):
    os.mkdir(wcroot_path)

  # Algorithm:
  #
  # 1. Iterate over all subtree repositories to request:
  # 1.1. The last has been pushed svn commit with the revision from the git local repository, including the git commit hash and timestamp.
  # 1.2. The all not pushed svn commits with the revisions from the svn remote repository, including the svn commit timestamp.
  #
  # 2. Compare parent-child repositories on timestamps between the last has been pushed svn commit and the first not pushed svn commit:
  # 2.1. If the first not pushed svn commit which has an association with the parent/child git repository is not after a timestamp of
  #      the last has been pushed svn commit in the child/parent git repository, then the pushed one commit is ahead to the not pushed one
  #      and must be unpushed back to the not pushed state (exceptional case, can happen, for example, if svn-to-git commit
  #      timestamps is not in sync and must be explicitly offsetted).
  # 2.2. Otherwise a not pushed one svn commit can be pushed into the git repository in an ordered push, where all git pushes must happen
  #      beginning from the most child git repository to the most parent git repository.
  #
  # 3. Fetch the first not pushed to the git the svn commit, rebase and push it into the git repository one-by-one beginning from the
  #    most child git repository to the most parent git repository. If a parent repository does not have has svn commit to push with the
  #    same revision from a child repository, then anyway do merge and push changes into the parent git repository. This will introduce
  #    changes from children repositories into parent repositories even if a parent repository does not have has changes with the same svn
  #    revision from a child svn repository.
  #

  max_time_depth_in_multiple_svn_commits_fetch_sec = get_max_time_depth_in_multiple_svn_commits_fetch_sec()

  with local_cwd(' ->> cwd: `{0}`...', ' -<< cwd: `{0}`...', wcroot_path), \
       GitReposListReader(configure_dir + '/git_repos.lst') as git_repos_reader, ServiceProcCache() as svc_proc_cache:
    executed_procs = cache_init_service_proc(svc_proc_cache)

    with tkl.OnExit(lambda: cache_close_running_procs(executed_procs, svc_proc_cache)):
      column_names, column_widths = get_git_svn_repos_list_table_params()

      if git_subtrees_root is None:
        git_subtrees_root = wcroot_path + '/.git/.pyxvcs/gitwc'

      git_svn_repo_tree_dict, git_svn_repo_tree_tuple_ref_preorder_list, svn_repo_root_to_uuid_dict, git_svn_params_dict = \
        read_git_svn_repo_list(git_repos_reader, scm_token, wcroot_path, git_subtrees_root, column_names, column_widths)

      print('- GIT switching...')

      for git_svn_repo_tree_tuple_ref in git_svn_repo_tree_tuple_ref_preorder_list:
        repo_params_ref = git_svn_repo_tree_tuple_ref[0]

        parent_tuple_ref = repo_params_ref['parent_tuple_ref']

        ordinal_index_prefix_str = repo_params_ref['ordinal_index_prefix_str']

        remote_name = repo_params_ref['remote_name']

        parent_git_path_prefix = repo_params_ref['parent_git_path_prefix']

        git_local_branch = repo_params_ref['git_local_branch']
        git_remote_branch = repo_params_ref['git_remote_branch']

        if not parent_tuple_ref is None:
          subtree_git_wcroot = repo_params_ref['git_wcroot']

        with conditional(not parent_tuple_ref is None,
                         local_cwd(' ->> cwd: `{0}`...', ' -<< cwd: `{0}`...', subtree_git_wcroot) if not parent_tuple_ref is None else None):
          git_local_refspec_token = get_git_local_refspec_token(git_local_branch, git_remote_branch)

          ret = call_git_no_except(['show-ref', '--verify', git_local_refspec_token])

          # CAUTION:
          #   1. The index file cleanup might be required here to avoid the error messsage:
          #      `fatal: cannot switch branch while merging`
          #   2. The Working Copy cleanup is required together with the index file cleanup to avoid later a problem with a
          #      merge around untracked files with the error message:
          #      `error: The following untracked working tree files would be overwritten by merge`
          #      `Please move or remove them before you merge.`.

          # CAUTION:
          #   1. Is required to avoid a fetch into the `master` branch by default.
          #
          if not ret[0]:
            call_git(['switch', '--no-guess', git_local_branch])
          else:
            # recreate the local branch
            git_recreate_head_branch(git_local_branch)

          print('---')

      print('- GIT fetching...')

      for git_svn_repo_tree_tuple_ref in git_svn_repo_tree_tuple_ref_preorder_list:
        repo_params_ref = git_svn_repo_tree_tuple_ref[0]

        parent_tuple_ref = repo_params_ref['parent_tuple_ref']

        ordinal_index_prefix_str = repo_params_ref['ordinal_index_prefix_str']

        remote_name = repo_params_ref['remote_name']
        parent_remote_name = repo_params_ref['parent_remote_name']

        git_reporoot = repo_params_ref['git_reporoot']
        svn_reporoot = repo_params_ref['svn_reporoot']

        parent_git_path_prefix = repo_params_ref['parent_git_path_prefix']
        svn_path_prefix = repo_params_ref['svn_path_prefix']

        git_local_branch = repo_params_ref['git_local_branch']
        git_remote_branch = repo_params_ref['git_remote_branch']

        if not parent_tuple_ref is None:
          subtree_git_wcroot = repo_params_ref['git_wcroot']

        with conditional(not parent_tuple_ref is None,
                         local_cwd(' ->> cwd: `{0}`...', ' -<< cwd: `{0}`...', subtree_git_wcroot) if not parent_tuple_ref is None else None):
          git_local_refspec_token = get_git_local_refspec_token(git_local_branch, git_remote_branch)
          git_remote_refspec_token, git_remote_local_refspec_token = \
            get_git_remote_refspec_token_tuple(remote_name, git_local_branch, git_remote_branch)

          # get last pushed commit hash
          git_last_pushed_commit_hash = get_git_last_pushed_commit_hash(git_reporoot, git_remote_local_refspec_token)

          if not git_last_pushed_commit_hash is None:
            git_fetch_refspec_token = get_git_fetch_refspec_token(git_local_branch, git_remote_branch)

            call_git(['fetch', remote_name, git_fetch_refspec_token])

          # 1. compare the last pushed commit hash with the last fetched commit hash and if different, then revert FETCH_HEAD
          # 2. additionally, compare the last pushed commit hash with the head commit hash and if different then revert HEAD

          git_reset_if_head_is_not_last_pushed(git_last_pushed_commit_hash, git_local_refspec_token, git_remote_refspec_token,
            reset_hard = reset_hard)

          print('---')

      # 1. + 2.
      #

      has_notpushed_svn_revisions_to_update = \
        update_git_svn_repo_fetch_state(git_svn_repo_tree_tuple_ref_preorder_list, git_svn_params_dict,
          max_time_depth_in_multiple_svn_commits_fetch_sec, is_first_time_update = True)

      # we still have to checkout before quit
      if has_notpushed_svn_revisions_to_update:
        print('- GIT-SVN fetching...')

        for git_svn_repo_tree_tuple_ref in git_svn_repo_tree_tuple_ref_preorder_list:
          repo_params_ref = git_svn_repo_tree_tuple_ref[0]
          fetch_state_ref = git_svn_repo_tree_tuple_ref[1]

          parent_tuple_ref = repo_params_ref['parent_tuple_ref']

          ordinal_index_prefix_str = repo_params_ref['ordinal_index_prefix_str']

          remote_name = repo_params_ref['remote_name']

          git_reporoot = repo_params_ref['git_reporoot']
          svn_reporoot = repo_params_ref['svn_reporoot']

          parent_git_path_prefix = repo_params_ref['parent_git_path_prefix']

          git_local_branch = repo_params_ref['git_local_branch']
          git_remote_branch = repo_params_ref['git_remote_branch']

          git_svn_fetch_ignore_paths_regex = repo_params_ref['git_ignore_paths_regex']

          if not parent_tuple_ref is None:
            subtree_git_wcroot = repo_params_ref['git_wcroot']

          with conditional(not parent_tuple_ref is None,
                           local_cwd(' ->> cwd: `{0}`...', ' -<< cwd: `{0}`...', subtree_git_wcroot) if not parent_tuple_ref is None else None):
            last_pruned_git_svn_commit_dict = fetch_state_ref['last_pruned_git_svn_commit_dict']

            git_svn_fetch_cmdline_list = []

            if len(git_svn_fetch_ignore_paths_regex) > 0:
              git_svn_fetch_cmdline_list.append('--ignore-paths=' + git_svn_fetch_ignore_paths_regex)

            # git-svn (re)fetch next svn revision

            # svn fetch and git push is available only on a writable (not readonly) repository or if git-svn commits is not requested for retain as parent commits
            if not fetch_state_ref['is_read_only_repo'] or retain_commit_git_svn_parents:
              last_pushed_git_svn_commit = fetch_state_ref['last_pushed_git_svn_commit']
              last_pushed_git_svn_commit_rev = last_pushed_git_svn_commit[0]

              git_svn_fetch(git_svn_repo_tree_tuple_ref, last_pushed_git_svn_commit_rev, git_svn_fetch_cmdline_list,
                last_pruned_git_svn_commit_dict,
                prune_empty_git_svn_commits)

              # revert again if last fetch has broke the HEAD

              # get last pushed commit hash
              git_last_pushed_commit_hash = get_git_last_pushed_commit_hash(git_reporoot, git_remote_local_refspec_token)

              git_local_refspec_token = get_git_local_refspec_token(git_local_branch, git_remote_branch)
              git_remote_refspec_token, git_remote_local_refspec_token = \
                get_git_remote_refspec_token_tuple(remote_name, git_local_branch, git_remote_branch)

              git_reset_if_head_is_not_last_pushed(git_last_pushed_commit_hash, git_local_refspec_token, git_remote_refspec_token,
                reset_hard = reset_hard)

            print('---')

      print('- GIT checkouting...')

      for git_svn_repo_tree_tuple_ref in git_svn_repo_tree_tuple_ref_preorder_list:
        repo_params_ref = git_svn_repo_tree_tuple_ref[0]

        parent_tuple_ref = repo_params_ref['parent_tuple_ref']

        ordinal_index_prefix_str = repo_params_ref['ordinal_index_prefix_str']

        remote_name = repo_params_ref['remote_name']

        parent_git_path_prefix = repo_params_ref['parent_git_path_prefix']

        git_local_branch = repo_params_ref['git_local_branch']
        git_remote_branch = repo_params_ref['git_remote_branch']

        if not parent_tuple_ref is None:
          subtree_git_wcroot = repo_params_ref['git_wcroot']

        with conditional(not parent_tuple_ref is None,
                         local_cwd(' ->> cwd: `{0}`...', ' -<< cwd: `{0}`...', subtree_git_wcroot) if not parent_tuple_ref is None else None):
          git_local_refspec_token = get_git_local_refspec_token(git_local_branch, git_remote_branch)

          ret = call_git_no_except(['show-ref', '--verify', git_local_refspec_token])

          # CAUTION:
          #   1. Is required to avoid a fetch into the `master` branch by default.
          #
          if not ret[0]:
            call_git(['switch', '--no-guess', git_local_branch])

            # CAUTION:
            #   The HEAD reference still can be not initialized after the `git switch ...` command.
            #   We have to try to initialize it from here.
            #
            call_git(['checkout', '--no-guess', git_local_branch])
          else:
            # recreate the local branch
            git_recreate_head_branch(git_local_branch)

          print('---')

      if not has_notpushed_svn_revisions_to_update:
        return

      print('- Checking parent-child GIT/SVN repositories for the last fetch state consistency...')

      for git_svn_repo_tree_tuple_ref in git_svn_repo_tree_tuple_ref_preorder_list:
        repo_params_ref = git_svn_repo_tree_tuple_ref[0]

        parent_tuple_ref = repo_params_ref['parent_tuple_ref']
        if not parent_tuple_ref is None:
          parent_repo_params_ref = parent_tuple_ref[0]
          parent_fetch_state_ref = parent_tuple_ref[1]

          child_repo_params_ref = git_svn_repo_tree_tuple_ref[0]
          child_fetch_state_ref = git_svn_repo_tree_tuple_ref[1]

          # We exclude a compare of GIT repositories has a reference to different SVN repositories, because in that case a child
          # GIT repository (must be already a leaf in the tree in the previous check) is in a read only mode, where the push
          # command is not applicable.

          parent_svn_repo_uuid = parent_repo_params_ref['svn_repo_uuid']


          child_remote_name =  child_repo_params_ref['remote_name']
          child_svn_repo_uuid = child_repo_params_ref['svn_repo_uuid']

          is_parent_read_only_repo = parent_fetch_state_ref['is_read_only_repo'] # just in case
          is_child_read_only_repo = child_fetch_state_ref['is_read_only_repo']

          # If uuids of parent-child svn repositories are different, then the child git repository must be a tree leaf
          # (a builtin check in the `read_git_svn_repo_list` function) and in a read only state.
          if parent_svn_repo_uuid != child_svn_repo_uuid:
            if is_child_read_only_repo != True or not is_child_read_only_repo is True: # double compare to check object id's too!
              raise Exception('the child git repository must be a read only repository: remote_name=`{0}`'.format(child_remote_name))

      # 3.
      #

      max_time_depth_in_multiple_svn_commits_fetch_sec = get_max_time_depth_in_multiple_svn_commits_fetch_sec()

      min_tree_time_of_last_notpushed_svn_commit = get_root_min_tree_time_of_last_notpushed_svn_commit(git_svn_repo_tree_tuple_ref_preorder_list)

      has_notpushed_svn_revisions_to_update = True

      # CAUTION:
      #   1. We must always execute the Algorithm A at least one more time, even if no notpushed svn revisions, because the Algorithm A merges
      #      the children repositories left behind in the Algorithm B!
      #      Read the further detail below.
      #

      # CAUTION: Do-While equivalent!
      while True:
        print('- Collecting latest been pushed git-svn commits and notpushed svn commits...')

        if has_notpushed_svn_revisions_to_update:
          notpushed_svn_commit_by_timestamp_dict = collect_notpushed_svn_revisions_ordered_by_timestamp(git_svn_repo_tree_tuple_ref_preorder_list)
          if not len(notpushed_svn_commit_by_timestamp_dict) > 0:
            notpushed_svn_commit_by_timestamp_dict = None
        else:
          notpushed_svn_commit_by_timestamp_dict = None

        # convert sorted dictionary into the list of tuples to be able to remove items while iterating the list
        notpushed_svn_commit_sorted_by_timestamp_tuple_list = []
        if not notpushed_svn_commit_by_timestamp_dict is None:
          for notpushed_svn_commit_timestamp, notpushed_svn_commit_list in sorted(notpushed_svn_commit_by_timestamp_dict.items()):
            for notpushed_svn_commit_tuple in notpushed_svn_commit_list:
              notpushed_svn_commit_sorted_by_timestamp_tuple_list.append(
                # rev, timestamp, datetime, ref
                (notpushed_svn_commit_tuple[0], notpushed_svn_commit_timestamp, notpushed_svn_commit_tuple[1], notpushed_svn_commit_tuple[2])
              )

        # CAUTION:
        #   1. Algorithm A is designed to be BEFORE the algorithm B because of the
        #      interruption issue. If any algorithm would be interrupted at any place
        #      for some reason, then the logic of both should not relie on
        #      synchronization and simple algorithm restart from beginning must be
        #      enough to self synchronize of the entire process of fetching, merging
        #      and pushing in the same order as before the interruption!
        #

        # Algorithm A:
        #   Collect been pushed commits with max timestamp and merge them as subtrees
        #   in parent repositories up to the root repository or upto intermediate
        #   parent repository in the repositories tree.
        #   If there is other commits with the same timestamp on the way from a child
        #   repository to a parent repository, then merge them together where parent
        #   repository changes must be applied before the changes from a child
        #   repository with the same timestamp.
        #
        #   1. Search for the most latest pushed commit(s) in the repositories tree,
        #      collect N repositories if there is N been pushed commits with max
        #      timestamp (N >= 1).
        #   2. Cleanup the list from commits which are direct descendants to other
        #      commits from the list because they are already processed in previous
        #      iterations of the algorithm A.
        #   3. Check the timestamp of the first commit from the list of not yet pushed
        #      (notpushed) svn commits.
        #   3.1. If it has the same timestamp as the previously latest been pushed svn
        #        commit(s) with maximum timestamp, then check it on a relation with them
        #        and if the commit is a direct or indirect ancestor to one or more
        #        repositories with the latest been pushed svn commits, then make a merge
        #        the commits between repositories with the latest been pushed svn
        #        commit(s) excluding it and the repository with not yet pushed
        #        (notpushed) svn commit including it (merge it with child repository
        #        subrees).
        #   3.2. If the first commit from the list of not yet pushed (notpushed) svn
        #        commits has no relation to the latest been pushed svn commits with the
        #        same timestamp, then let it be pushed as is in the Algorithm B without
        #        merge it into parent repositories in the algorithm A.
        #   3.3. If the first commit from the list of not yet pushed (notpushed) svn
        #        commits has a greater timestamp, then make a merge the commits between
        #        the latest been pushed svn commit(s) excluding it and the root
        #        repository including it (merge it with child repository subrees).

        # Algorithm B:
        #   After all previously pushed commits is merged into parent repositories in
        #   the algorithm A, the currently pending not yet pushed (notpushed) svn commit
        #   for a repository will be pushed as is here without merge into parent
        #   repositories. It will be merged into parent repositories later in the next
        #   iteration of the algorithm A.

        # CAUTION: Do-While equivalent!
        while True:
          # === Algorithm A ===
          #

          print('- GIT-SVN parent repositories multiple merging and pushing is started.')

          collect_multiple_parent_repos_to_merge_and_push = True
          while collect_multiple_parent_repos_to_merge_and_push:
            # 1.
            #

            (last_pushed_git_svn_commits_by_max_author_timestamp_list, last_pushed_git_svn_commit_max_author_timestamp) = \
              collect_last_pushed_git_svn_commits_by_max_author_timestamp(git_svn_repo_tree_tuple_ref_preorder_list)

            # CAUTION:
            #   1. We must check on the root repository, because if the list contains the root repository,
            #      then no need to check others, because all commits in the repository tree must be already been pushed without skips.
            #
            if not len(last_pushed_git_svn_commits_by_max_author_timestamp_list) > 0 or \
               last_pushed_git_svn_commits_by_max_author_timestamp_list[0][0]['parent_tuple_ref'] is None:
              break

            # 2.
            #

            last_pushed_git_svn_commits_by_max_author_timestamp_list = \
              remove_git_svn_tree_direct_descendants_from_list(last_pushed_git_svn_commits_by_max_author_timestamp_list)

            # 3.
            #

            first_notpushed_svn_commit_is_ancestor_to_last_pushed_git_svn_commits_in_list = False
            if len(notpushed_svn_commit_sorted_by_timestamp_tuple_list) > 0:
              # rev, timestamp, datetime, ref
              first_notpushed_svn_commit_sorted_by_timestamp_tuple = notpushed_svn_commit_sorted_by_timestamp_tuple_list[0]
              (first_notpushed_svn_commit_rev, first_notpushed_svn_commit_timestamp, first_notpushed_svn_commit_date_time, first_notpushed_svn_commit_repo_tree_tuple_ref) = \
                first_notpushed_svn_commit_sorted_by_timestamp_tuple

              if last_pushed_git_svn_commit_max_author_timestamp == first_notpushed_svn_commit_timestamp: # if equal then already valid versus all minimal timestamps
                first_notpushed_svn_commit_is_ancestor_to_last_pushed_git_svn_commits_in_list = \
                  if_git_svn_commit_is_ancestor_to_commits_in_list(first_notpushed_svn_commit_repo_tree_tuple_ref, last_pushed_git_svn_commits_by_max_author_timestamp_list)
                if not first_notpushed_svn_commit_is_ancestor_to_last_pushed_git_svn_commits_in_list:
                  # 3.2.
                  #
                  break # no need in the Algorithm A, use the Algorithm B
            else:
              first_notpushed_svn_commit_sorted_by_timestamp_tuple = None

            # 3.1. + 3.3.
            #

            git_svn_parent_merge_commit_list = []

            for git_svn_repo_tree_tuple_ref in reversed(git_svn_repo_tree_tuple_ref_preorder_list): # in reverse
              if git_svn_repo_tree_tuple_ref in last_pushed_git_svn_commits_by_max_author_timestamp_list:
                continue
              if if_git_svn_commit_is_ancestor_to_commits_in_list(git_svn_repo_tree_tuple_ref, last_pushed_git_svn_commits_by_max_author_timestamp_list):
                git_svn_parent_merge_commit_list.append(git_svn_repo_tree_tuple_ref)
              # 3.1. only
              #
              if first_notpushed_svn_commit_is_ancestor_to_last_pushed_git_svn_commits_in_list:
                # just quit on the target commit
                if git_svn_repo_tree_tuple_ref is first_notpushed_svn_commit_repo_tree_tuple_ref:
                  break

            if not len(git_svn_parent_merge_commit_list) > 0:
              raise Exception('fetch-merge-push sequence is corrupted, the collected list of parent repositories to merge is empty')

            # 1. Iterate over a commit children repositories, fetch the associated svn commits and merge them as a subtree into the parent commit.
            # 2. Merge the not yet pushed (notpushed) svn commit with the same timestamp at first as a parent repository changes.
            #

            git_svn_parent_merge_commit_list_size = len(git_svn_parent_merge_commit_list)

            for git_svn_parent_merge_commit_index, git_svn_repo_tree_tuple_ref in enumerate(git_svn_parent_merge_commit_list):
              is_last_parent_merge_commit = True if git_svn_parent_merge_commit_index == git_svn_parent_merge_commit_list_size - 1 else False

              parent_repo_params_ref = git_svn_repo_tree_tuple_ref[0]
              parent_fetch_state_ref = git_svn_repo_tree_tuple_ref[1]

              parent_parent_tuple_ref = parent_repo_params_ref['parent_tuple_ref']

              parent_remote_name = parent_repo_params_ref['remote_name']

              parent_ordinal_index_prefix_str = parent_repo_params_ref['ordinal_index_prefix_str']

              # the last merge commit must always be the root repository commit and the root repository commit must be the last merge commit
              if is_last_parent_merge_commit:
                if not parent_parent_tuple_ref is None:
                  raise Exception('fetch-merge-push sequence is corrupted, the last merge commit in a list of multiple parent repository commits must be always the root repository commit: remote_name=`{0}`'.format(remote_name))
              else:
                if parent_parent_tuple_ref is None:
                  raise Exception('fetch-merge-push sequence is corrupted, the root repository commit is not the last merge commit in a list of multiple parent repository commits: remote_name=`{0}`'.format(remote_name))

              # check on the root repository to stop the Algorithm A
              if is_last_parent_merge_commit:
                collect_multiple_parent_repos_to_merge_and_push = False

              parent_children_tuple_ref_list = parent_repo_params_ref['children_tuple_ref_list']

              parent_svn_reporoot = parent_repo_params_ref['svn_reporoot']

              parent_git_local_branch = parent_repo_params_ref['git_local_branch']
              parent_git_remote_branch = parent_repo_params_ref['git_remote_branch']

              parent_parent_git_path_prefix = parent_repo_params_ref['parent_git_path_prefix']
              parent_svn_path_prefix = parent_repo_params_ref['svn_path_prefix']

              git_svn_fetch_ignore_paths_regex = parent_repo_params_ref['git_ignore_paths_regex']

              if not parent_parent_tuple_ref is None:
                subtree_git_wcroot = parent_repo_params_ref['git_wcroot']

              parent_svn_repopath = parent_svn_reporoot + (('/' + parent_svn_path_prefix) if parent_svn_path_prefix != '' else '')

              with conditional(not parent_parent_tuple_ref is None,
                               local_cwd(' ->> cwd: `{0}`...', ' -<< cwd: `{0}`...', subtree_git_wcroot) if not parent_parent_tuple_ref is None else None):
                # svn fetch and git push is available only on a writable (not readonly) repository
                is_parent_read_only_repo = parent_fetch_state_ref['is_read_only_repo']
                if is_parent_read_only_repo:
                  raise Exception('fetch-merge-push sequence is corrupted, the being pushed repository is not writable: remote_name=`{0}`'.format(remote_name))

                parent_git_local_refspec_token = get_git_local_refspec_token(parent_git_local_branch, parent_git_remote_branch)

                ret = call_git_no_except(['show-ref', '--verify', parent_git_local_refspec_token])
                if not ret[0]:
                  is_parent_git_local_refspec_token_exist = True
                  # CAUTION:
                  #   1. We have to cleanup before the first merge command, otherwise the command may fail with the messages:
                  #      `error: your local changes would be overwritten by ...`
                  #      `hint: commit your changes or stash them to proceed.`
                  #   2. We have to reset with the `--hard`, otherwise another error message:
                  #      `error: The following untracked working tree files would be overwritten by merge:`
                  #
                  call_git(['reset', '--hard', parent_git_local_refspec_token])
                else:
                  is_parent_git_local_refspec_token_exist = False

                parent_last_pushed_git_svn_commit = parent_fetch_state_ref['last_pushed_git_svn_commit']
                parent_last_pushed_git_svn_commit_rev = parent_last_pushed_git_svn_commit[0]
                parent_last_pushed_git_svn_commit_hash = parent_last_pushed_git_svn_commit[1]
                parent_last_pushed_git_svn_commit_author_timestamp = parent_last_pushed_git_svn_commit[2]

                reuse_commit_message_refspec_token_or_commit_hash = None
                reuse_commit_message = None
                reuse_commit_author_timestamp = None
                reuse_commit_author_date_time = None

                parent_git_svn_trunk_first_commit_svn_rev = 0
                parent_git_svn_trunk_first_commit_hash = None
                parent_git_svn_trunk_first_commit_author_timestamp = None
                parent_git_svn_trunk_first_commit_author_date_time = None
                parent_git_svn_trunk_first_commit_commit_timestamp = None
                parent_git_svn_trunk_first_commit_commit_date_time = None
                num_overall_git_commits = 0
                parent_git_svn_trunk_first_commit_fetch_timestamp = None

                # ('<prefix>', '<merge_commit_hash>')
                child_read_tree_merge_commit_tuple_list = []
                has_parent_merge_commit = False

                # Collect refspecs or commit hashes w/o merge.
                #

                if first_notpushed_svn_commit_is_ancestor_to_last_pushed_git_svn_commits_in_list:
                  # make an svn branch fetch and merge at first as a parent change

                  git_svn_fetch_cmdline_list = []

                  if len(git_svn_fetch_ignore_paths_regex) > 0:
                    git_svn_fetch_cmdline_list.append('--ignore-paths=' + git_svn_fetch_ignore_paths_regex)

                  notpushed_svn_commit_list = parent_fetch_state_ref['notpushed_svn_commit_list']

                  parent_last_pruned_git_svn_commit_dict = parent_fetch_state_ref['last_pruned_git_svn_commit_dict']

                  git_svn_fetch(git_svn_repo_tree_tuple_ref, first_notpushed_svn_commit_rev, git_svn_fetch_cmdline_list,
                    parent_last_pruned_git_svn_commit_dict,
                    prune_empty_git_svn_commits, single_rev = True)

                  # drop fetched svn commit from the list
                  notpushed_svn_commit_sorted_by_timestamp_tuple_list.pop(0)

                  # CAUTION:
                  #   1. We must check whether the revision was really fetched because related fetch directory may not yet/already exist
                  #      (moved/deleted by the svn or completely filtered out by the `--ignore-paths` in the git) and if not, then get
                  #      skip the rebase/cherry-pick/push/<whatever>, otherwise the first or the followed commands may fail on actually
                  #      a not fetched svn commit!
                  #

                  # ignore errors because may call on not yet existed branch
                  parent_git_svn_trunk_remote_refspec_token = get_git_svn_trunk_remote_refspec_token(parent_remote_name)

                  ret = call_git_no_except(['show-ref', '--verify', parent_git_svn_trunk_remote_refspec_token])
                  if not ret[0]:
                    parent_git_svn_trunk_first_commit_svn_rev, parent_git_svn_trunk_first_commit_hash, \
                    parent_git_svn_trunk_first_commit_author_timestamp, parent_git_svn_trunk_first_commit_author_date_time, \
                    parent_git_svn_trunk_first_commit_commit_timestamp, parent_git_svn_trunk_first_commit_commit_date_time, \
                    num_overall_git_commits, \
                    parent_git_svn_trunk_first_commit_fetch_timestamp = \
                      get_last_git_svn_commit_by_git_log(parent_git_svn_trunk_remote_refspec_token,
                        parent_svn_reporoot, parent_svn_path_prefix, parent_parent_git_path_prefix,
                        first_notpushed_svn_commit_rev, git_svn_params_dict)

                  has_parent_merge_commit = (parent_git_svn_trunk_first_commit_svn_rev > 0)
                  if has_parent_merge_commit:
                    if parent_git_svn_trunk_first_commit_hash is None:
                      raise Exception('fetch-merge-push sequence is corrupted, last git-svn commit is not found in the git log output: svn_rev=`{0}` svn_repopath=`{1}` refspec={2}'.
                        format(parent_git_svn_trunk_first_commit_svn_rev, parent_svn_repopath, parent_git_svn_trunk_remote_refspec_token))

                    # the fetched svn revision is confirmed, can continue now

                    # NOTE: The attempts has been made to resolve all related conditions:
                    #   1. The `git svn rebase ...` can not handle unrelated histories properly, we have to use plain `git rebase ...` to handle that.
                    #   2. We can not use `git rebase ...` too because the `git-svn-trunk` branch can be incomplete and consist only of a single
                    #      and the last one commit which can involve incorrect rebase with an error message around a fall back rebase:
                    #      `patching base and 3-way merge`.
                    #   3. Additionally, the `git rebase ...` can skip commits and make no action even if commits exists, so we have to track that behaviour.
                    #   4. We can not use `git cherry-pick ...` too because of absence of the merge metadata (single commit parent instead of multiple) in
                    #      case of multiple child repository merge.
                    #   5. Additionally, the `git cherry-pick ...` can not handle a subtree prefix and merges all commits into the root directory of a commit.
                    #   6. We can not use `git pull ...` too because of a subsequent error message around a merge:
                    #      `error: You have not concluded your merge (MERGE_HEAD exists).`
                    #      `hint: Please, commit your changes before merging.`
                    #      `fatal: Exiting because of unfinished merge.`
                    #   7. We can not use `git subtree add ...` after `git merge ...` too because of a subsequent error message around a merge:
                    #      `Working tree has modifications.  Cannot add.`
                    #   8. We can not use `git subtree merge ...` too because of a subsequent error message around a merge:
                    #      `Working tree has modifications.  Cannot add.`
                    #

                    reuse_commit_message_refspec_token_or_commit_hash = parent_git_svn_trunk_first_commit_hash

                    ret = call_git(['log', '--max-count=1', '--format=%B', reuse_commit_message_refspec_token_or_commit_hash])
                    reuse_commit_message = ret[1].rstrip()

                    advance_svn_notpushed_commits_list(git_svn_repo_tree_tuple_ref, first_notpushed_svn_commit_rev - 1)
                  else:
                    print('- The svn commit merge from a parent repository is skipped, the respective svn commit revision was not found as the last fetched: fetched=' +
                      str(first_notpushed_svn_commit_rev) + ' first_found=' + str(parent_git_svn_trunk_first_commit_svn_rev))

                # create child branches per last pushed commit from a child repository
                git_fetch_child_subtree_merge_branches(git_svn_repo_tree_tuple_ref, parent_children_tuple_ref_list,
                  git_subtrees_root, svn_repo_root_to_uuid_dict, git_svn_params_dict)

                # not empty child branches list
                child_subtree_branch_refspec_list = git_get_local_branch_refspec_list('^refs/heads/[^-]+--subtree')

                if child_subtree_branch_refspec_list is None or not len(child_subtree_branch_refspec_list) > 0:
                  raise Exception('fetch-merge-push sequence is corrupted, the children repository branch list is empty')

                # CAUTION:
                #   We can check a parent/child on an ahead/behind state ONLY after a branch prune from empty commits which happens
                #   after an svn repository fetch in the `git_svn_fetch` function. So we check it here immediately after the fetch
                #   even if a parent repository commit does not found.
                #
                if not disable_parent_child_ahead_behind_check:
                  git_check_if_parent_child_in_ahead_behind_state(git_svn_repo_tree_tuple_ref, recursively = True)

                git_svn_child_merge_commit_list_size = len(parent_children_tuple_ref_list)

                if not git_svn_child_merge_commit_list_size > 0:
                  raise Exception('fetch-merge-push sequence is corrupted, the parent repository does not have a child repository')

                max_child_git_svn_commit_rev = 0  # must be 0 instead of None
                max_child_last_pushed_git_svn_commit_author_timestamp = 0
                max_child_last_pushed_git_svn_commit_author_date_time = ''

                for child_tuple_ref in parent_children_tuple_ref_list:
                  child_repo_params_ref = child_tuple_ref[0]
                  child_fetch_state_ref = child_tuple_ref[1]

                  child_remote_name = child_repo_params_ref['remote_name']

                  child_svn_reporoot = child_repo_params_ref['svn_reporoot']

                  child_git_local_branch = child_repo_params_ref['git_local_branch']
                  child_git_remote_branch = child_repo_params_ref['git_remote_branch']

                  child_branch_refspec = 'refs/heads/' + child_remote_name + '--subtree'

                  # filter out empty branches
                  if child_branch_refspec in child_subtree_branch_refspec_list:
                    child_parent_git_path_prefix = child_repo_params_ref['parent_git_path_prefix']

                    merge_commit_hash = get_git_local_head_commit_hash(child_branch_refspec)

                    child_read_tree_merge_commit_tuple_list.append((child_parent_git_path_prefix + '/', merge_commit_hash))

                    child_last_pushed_git_svn_commit = child_fetch_state_ref['last_pushed_git_svn_commit']
                    child_last_pushed_git_svn_commit_rev = child_last_pushed_git_svn_commit[0]
                    child_last_pushed_git_svn_commit_author_timestamp = child_last_pushed_git_svn_commit[2]
                    child_last_pushed_git_svn_commit_author_date_time = child_last_pushed_git_svn_commit[3]

                    if max_child_git_svn_commit_rev < child_last_pushed_git_svn_commit_rev:
                      max_child_git_svn_commit_rev = child_last_pushed_git_svn_commit_rev
                    if max_child_last_pushed_git_svn_commit_author_timestamp < child_last_pushed_git_svn_commit_author_timestamp:
                      max_child_last_pushed_git_svn_commit_author_timestamp = child_last_pushed_git_svn_commit_author_timestamp
                      max_child_last_pushed_git_svn_commit_author_date_time = child_last_pushed_git_svn_commit_author_date_time

                    # take message from the first commit in the list if not taken from a parent commit
                    if reuse_commit_message_refspec_token_or_commit_hash is None:
                      reuse_commit_message_refspec_token_or_commit_hash = child_branch_refspec

                      # replace value of the `git-svn-id` token in the commit message (a child svn repository token) by a parent svn repostiory token
                      ret = call_git(['log', '--max-count=1', '--format=%B', reuse_commit_message_refspec_token_or_commit_hash])
                      reuse_commit_message = ret[1].rstrip()

                      git_svn_id_regex_match = re.search(r'^git-svn-id:\s+([^\n\r]+)$', reuse_commit_message, flags = re.MULTILINE)
                      if git_svn_id_regex_match:
                        reuse_commit_message = \
                          re.sub(r'^git-svn-id:\s+([^@]+(@\d+)?\s+[^\n\r]+)$',
                            r'git-svn-from-id: \1' + '\n' +
                            r'git-svn-to-id: ' + parent_svn_repopath +
                            (r'\2 ' if child_svn_reporoot == parent_svn_reporoot else r' ') +
                            svn_repo_root_to_uuid_dict[parent_svn_reporoot],
                            reuse_commit_message, flags = re.MULTILINE)
                      else:
                        git_svn_to_id_match = re.search(r'^git-svn-to-id:\s+([^\n\r]+)$', reuse_commit_message, flags = re.MULTILINE)
                        reuse_commit_message = \
                          re.sub(r'^git-svn-from-id:\s+([^\n\r]+)(?:\r?\n)?', '', reuse_commit_message, flags = re.MULTILINE)
                        if git_svn_to_id_match:
                          reuse_commit_message = \
                            re.sub(r'^git-svn-to-id:\s+([^@]+(@\d+)?\s+[^\n\r]+)$',
                              r'git-svn-from-id: \1' + '\n' +
                              r'git-svn-to-id: ' + parent_svn_repopath +
                              (r'\2 ' if child_svn_reporoot == parent_svn_reporoot else r' ') +
                              svn_repo_root_to_uuid_dict[parent_svn_reporoot],
                              reuse_commit_message, flags = re.MULTILINE)
                    else:
                      if reuse_commit_message is None:
                        reuse_commit_message = ''

                      # replace value of the `git-svn-id` token in the commit message (a child svn repository token) by a parent svn repostiory token
                      ret = call_git(['log', '--max-count=1', '--format=%B', child_branch_refspec])
                      reuse_another_commit_message = ret[1].rstrip()

                      git_svn_id_regex_match = re.search(r'^git-svn-id:\s+([^@]+(@\d+)?\s+[^\n\r]+)$', reuse_another_commit_message, flags = re.MULTILINE)
                      if git_svn_id_regex_match:
                        reuse_commit_message += ('\n' if reuse_commit_message[-1] != '\n' else '') + \
                          r'git-svn-from-id: ' + git_svn_id_regex_match.group(1) + '\n' + \
                          r'git-svn-to-id: ' + parent_svn_repopath + \
                          ((git_svn_id_regex_match.group(2) + r' ') if child_svn_reporoot == parent_svn_reporoot else r' ') + \
                          svn_repo_root_to_uuid_dict[parent_svn_reporoot] + '\n'
                      else:
                        git_svn_to_id_match_iter = re.finditer(r'^git-svn-to-id:\s+([^@]+(@\d+)?\s+[^\n\r]+)$', reuse_another_commit_message, flags = re.MULTILINE)
                        for git_svn_to_id_match in git_svn_to_id_match_iter:
                          reuse_commit_message += ('\n' if reuse_commit_message[-1] != '\n' else '') + \
                            r'git-svn-from-id: ' + git_svn_to_id_match.group(1) + '\n' + \
                            r'git-svn-to-id: ' + parent_svn_repopath + \
                            ((git_svn_to_id_match.group(2) + r' ') if child_svn_reporoot == parent_svn_reporoot else r' ') + \
                            svn_repo_root_to_uuid_dict[parent_svn_reporoot] + '\n'

                if reuse_commit_author_date_time is None:
                  reuse_commit_author_timestamp = max_child_last_pushed_git_svn_commit_author_timestamp
                  reuse_commit_author_date_time = max_child_last_pushed_git_svn_commit_author_date_time

                if not max_child_git_svn_commit_rev > 0:
                  raise Exception('fetch-merge-push sequence is corrupted, no one child repository branch is merged')

                # CAUTION:
                #   Before a push we must check if a commit was already merged, otherwise a push command would throw an error:
                #   `error: failed to push some refs to '...'`
                #   `hint: Updates were rejected because the tip of your current branch is behind`
                #   `hint: its remote counterpart. Integrate the remote changes (e.g.`
                #   `hint: 'git pull ...') before pushing again.`
                #
                if not has_parent_merge_commit or parent_last_pushed_git_svn_commit_author_timestamp != reuse_commit_author_timestamp:
                  git_merge_and_push(
                    parent_remote_name, parent_svn_reporoot, parent_svn_path_prefix, parent_git_local_branch, parent_git_remote_branch,
                    parent_fetch_state_ref, parent_children_tuple_ref_list, parent_last_pushed_git_svn_commit_hash,
                    is_parent_git_local_refspec_token_exist, has_parent_merge_commit, parent_git_svn_trunk_first_commit_hash,
                    child_read_tree_merge_commit_tuple_list, retain_commit_git_svn_parents,
                    reuse_commit_author_date_time, reuse_commit_message, reuse_commit_message_refspec_token_or_commit_hash,
                    git_svn_params_dict)

                  # CAUTION:
                  #   We have to reset the working directory after the push to avoid next merge problems after merge from multiple child branches.
                  #   Otherwise the `git rm ....` command above can fail with the message: `fatal: pathspec '<prefix>' did not match any files`
                  #
                  call_git(['reset', '--hard', parent_git_local_branch])

                # remove all subtree merge branches
                git_remove_child_subtree_merge_branches(parent_children_tuple_ref_list)

          # === Algorithm B ===
          #

          print('- GIT-SVN single parent repository merging and pushing is started.')

          if len(notpushed_svn_commit_sorted_by_timestamp_tuple_list) > 0:
            # rev, timestamp, datetime, ref
            first_notpushed_svn_commit_sorted_by_timestamp_tuple = notpushed_svn_commit_sorted_by_timestamp_tuple_list.pop(0)
            (first_notpushed_svn_commit_rev, first_notpushed_svn_commit_timestamp, first_notpushed_svn_commit_date_time, first_notpushed_svn_commit_repo_tree_tuple_ref) = \
              first_notpushed_svn_commit_sorted_by_timestamp_tuple

            repo_params_ref = first_notpushed_svn_commit_repo_tree_tuple_ref[0]
            fetch_state_ref = first_notpushed_svn_commit_repo_tree_tuple_ref[1]

            ordinal_index_prefix_str = repo_params_ref['ordinal_index_prefix_str']

            remote_name = repo_params_ref['remote_name']

            children_tuple_ref_list = repo_params_ref['children_tuple_ref_list']

            min_ro_tree_time_of_first_notpushed_svn_commit = get_subtree_min_ro_tree_time_of_first_notpushed_svn_commit(first_notpushed_svn_commit_repo_tree_tuple_ref)

            if not min_ro_tree_time_of_first_notpushed_svn_commit is None:
              min_ro_tree_time_of_first_notpushed_svn_commit_timestamp = min_ro_tree_time_of_first_notpushed_svn_commit[0]

              if first_notpushed_svn_commit_timestamp >= min_ro_tree_time_of_first_notpushed_svn_commit_timestamp:
                min_ro_tree_svn_commit_repo_tree_tuple_ref = min_ro_tree_time_of_first_notpushed_svn_commit[2]
                min_ro_tree_repo_params_ref = min_ro_tree_svn_commit_repo_tree_tuple_ref[0]
                min_ro_tree_remote_name = min_ro_tree_repo_params_ref['remote_name']
                raise Exception('The `' + min_ro_tree_remote_name +
                  '` read only repository must be pushed from svn in another project before continue with the current project')

            if not min_tree_time_of_last_notpushed_svn_commit is None:
              min_tree_time_of_last_notpushed_svn_commit_timestamp = min_tree_time_of_last_notpushed_svn_commit[0]

              if min_tree_time_of_last_notpushed_svn_commit_timestamp < first_notpushed_svn_commit_timestamp:
                break

            parent_tuple_ref = repo_params_ref['parent_tuple_ref']

            svn_reporoot = repo_params_ref['svn_reporoot']

            git_local_branch = repo_params_ref['git_local_branch']
            git_remote_branch = repo_params_ref['git_remote_branch']

            parent_git_path_prefix = repo_params_ref['parent_git_path_prefix']
            git_path_prefix = repo_params_ref['git_path_prefix']
            svn_path_prefix = repo_params_ref['svn_path_prefix']

            git_svn_fetch_ignore_paths_regex = repo_params_ref['git_ignore_paths_regex']

            if not parent_tuple_ref is None:
              subtree_git_wcroot = repo_params_ref['git_wcroot']

            svn_repopath = svn_reporoot + (('/' + svn_path_prefix) if svn_path_prefix != '' else '')

            with conditional(not parent_tuple_ref is None,
                             local_cwd(' ->> cwd: `{0}`...', ' -<< cwd: `{0}`...', subtree_git_wcroot) if not parent_tuple_ref is None else None):
              # svn fetch and git push is available only on a writable (not readonly) repository
              is_read_only_repo = fetch_state_ref['is_read_only_repo']
              if is_read_only_repo:
                raise Exception('fetch-merge-push sequence is corrupted, the being pushed repository is not writable: remote_name=`{0}`'.format(remote_name))

              git_local_refspec_token = get_git_local_refspec_token(git_local_branch, git_remote_branch)

              ret = call_git_no_except(['show-ref', '--verify', git_local_refspec_token])
              if not ret[0]:
                is_parent_git_local_refspec_token_exist = True
                # CAUTION:
                #   1. We have to reset with the `--hard`, otherwise error message:
                #      `error: The following untracked working tree files would be overwritten by merge:`
                #
                call_git(['reset', '--hard', git_local_refspec_token])
              else:
                is_parent_git_local_refspec_token_exist = False

              git_svn_fetch_cmdline_list = []

              if len(git_svn_fetch_ignore_paths_regex) > 0:
                git_svn_fetch_cmdline_list.append('--ignore-paths=' + git_svn_fetch_ignore_paths_regex)

              last_pushed_git_svn_commit = fetch_state_ref['last_pushed_git_svn_commit']
              last_pushed_git_svn_commit_rev = last_pushed_git_svn_commit[0]
              last_pushed_git_svn_commit_hash = last_pushed_git_svn_commit[1]

              notpushed_svn_commit_list = fetch_state_ref['notpushed_svn_commit_list']

              last_pruned_git_svn_commit_dict = fetch_state_ref['last_pruned_git_svn_commit_dict']

              git_svn_fetch(first_notpushed_svn_commit_repo_tree_tuple_ref, first_notpushed_svn_commit_rev, git_svn_fetch_cmdline_list,
                last_pruned_git_svn_commit_dict,
                prune_empty_git_svn_commits, single_rev = True)

              # CAUTION:
              #   1. We must check whether the revision was really fetched because related fetch directory may not yet/already exist
              #      (moved/deleted by the svn or completely filtered out by the `--ignore-paths` in the git) and if not, then get
              #      skip the rebase/cherry-pick/push/<whatever>, otherwise the first or the followed commands may fail on actually
              #      a not fetched svn commit!
              #

              # ignore errors because may call on not yet existed branch
              git_svn_trunk_remote_refspec_token = get_git_svn_trunk_remote_refspec_token(remote_name)

              ret = call_git_no_except(['show-ref', '--verify', git_svn_trunk_remote_refspec_token])
              if not ret[0]:
                git_svn_trunk_first_commit_svn_rev, git_svn_trunk_first_commit_hash, \
                git_svn_trunk_first_commit_author_timestamp, git_svn_trunk_first_commit_author_date_time, \
                git_svn_trunk_first_commit_commit_timestamp, git_svn_trunk_first_commit_commit_date_time, \
                num_overall_git_commits, \
                git_svn_trunk_first_commit_fetch_timestamp = \
                  get_last_git_svn_commit_by_git_log(git_svn_trunk_remote_refspec_token,
                    svn_reporoot, svn_path_prefix, git_path_prefix,
                    first_notpushed_svn_commit_rev, git_svn_params_dict)
              else:
                git_svn_trunk_first_commit_svn_rev = 0
                git_svn_trunk_first_commit_hash = None
                git_svn_trunk_first_commit_author_timestamp = None
                git_svn_trunk_first_commit_author_date_time = None
                git_svn_trunk_first_commit_commit_timestamp = None
                git_svn_trunk_first_commit_commit_date_time = None
                num_overall_git_commits = 0
                git_svn_trunk_first_commit_fetch_timestamp = None

              has_parent_merge_commit = (git_svn_trunk_first_commit_svn_rev > 0)
              if has_parent_merge_commit:
                if git_svn_trunk_first_commit_hash is None:
                  raise Exception('fetch-merge-push sequence is corrupted, last git-svn commit is not found in the git log output: svn_rev=`{0}` svn_repopath=`{1}` refspec={2}'.
                    format(git_svn_trunk_first_commit_svn_rev, svn_repopath, git_svn_trunk_remote_refspec_token))

                # the fetched svn revision is confirmed, can continue now

                advance_svn_notpushed_commits_list(first_notpushed_svn_commit_repo_tree_tuple_ref, first_notpushed_svn_commit_rev - 1)

                # create child branches per last pushed commit from a child repository
                git_fetch_child_subtree_merge_branches(first_notpushed_svn_commit_repo_tree_tuple_ref, children_tuple_ref_list,
                  git_subtrees_root, svn_repo_root_to_uuid_dict, git_svn_params_dict)

                # CAUTION:
                #   We can check a parent/child on an ahead/behind state ONLY after a branch prune from empty commits which happens
                #   after an svn repository fetch in the `git_svn_fetch` function. So we check it here immediately after the fetch.
                #
                if not disable_parent_child_ahead_behind_check:
                  git_check_if_parent_child_in_ahead_behind_state(first_notpushed_svn_commit_repo_tree_tuple_ref, recursively = True)

                # CAUTION:
                #   In the git a child repository branch must always be merged into a parent repository even if was merged for a previous svn revision(s),
                #   otherwise a parent repository commit won't contain changes made in a child repository in previous svn revision(s).
                #
                # ('<prefix>', '<commit_hash>')
                child_read_tree_merge_commit_tuple_list = []

                # not empty child branches list
                child_subtree_branch_refspec_list = git_get_local_branch_refspec_list('^refs/heads/[^-]+--subtree')

                if not child_subtree_branch_refspec_list is None and len(child_subtree_branch_refspec_list) > 0:
                  for child_tuple_ref in children_tuple_ref_list:
                    child_repo_params_ref = child_tuple_ref[0]

                    child_remote_name = child_repo_params_ref['remote_name']

                    child_branch_refspec = 'refs/heads/' + child_remote_name + '--subtree'

                    # filter out empty branches
                    if child_branch_refspec in child_subtree_branch_refspec_list:
                      child_parent_git_path_prefix = child_repo_params_ref['parent_git_path_prefix']

                      merge_commit_hash = get_git_local_head_commit_hash(child_branch_refspec)

                      child_read_tree_merge_commit_tuple_list.append((child_parent_git_path_prefix + '/', merge_commit_hash))

                git_merge_and_push(
                  remote_name, svn_reporoot, svn_path_prefix, git_local_branch, git_remote_branch,
                  fetch_state_ref, children_tuple_ref_list, last_pushed_git_svn_commit_hash,
                  is_parent_git_local_refspec_token_exist, has_parent_merge_commit, git_svn_trunk_first_commit_hash,
                  child_read_tree_merge_commit_tuple_list, retain_commit_git_svn_parents,
                  git_svn_trunk_first_commit_author_date_time, None, git_svn_trunk_first_commit_hash,
                  git_svn_params_dict)

                # CAUTION:
                #   We have to reset the working directory after the push to avoid next merge problems after merge from multiple child branches.
                #   Otherwise the `git rm ....` command above can fail with the message: `fatal: pathspec '<prefix>' did not match any files`
                #
                call_git(['reset', '--hard', git_local_branch])

                # remove all subtree merge branches
                git_remove_child_subtree_merge_branches(children_tuple_ref_list)
              else:
                print('- The push is skipped, the respective svn commit revision was not found as the last fetched: fetched=' +
                  str(first_notpushed_svn_commit_rev) + ' first_found=' + str(git_svn_trunk_first_commit_svn_rev))

          if not len(notpushed_svn_commit_sorted_by_timestamp_tuple_list) > 0:
            break

        has_notpushed_svn_revisions_to_update = \
          update_git_svn_repo_fetch_state(git_svn_repo_tree_tuple_ref_preorder_list, git_svn_params_dict,
            max_time_depth_in_multiple_svn_commits_fetch_sec, is_first_time_update = False)
        if not has_notpushed_svn_revisions_to_update:
          break

def git_append_read_tree_merge_commit_hash_to_prefix_dict(read_tree_prefix_to_merge_commit_hash_list_dict, prefix, merge_commit_hash):
  if merge_commit_hash is None:
    return

  read_tree_merge_commit_hash_list = read_tree_prefix_to_merge_commit_hash_list_dict.get(prefix)
  if not read_tree_merge_commit_hash_list is None:
    read_tree_merge_commit_hash_list.append(merge_commit_hash)
  else:
    read_tree_prefix_to_merge_commit_hash_list_dict[prefix] = [merge_commit_hash]

def git_merge_and_push(parent_remote_name, parent_svn_reporoot, parent_svn_path_prefix, parent_git_local_branch, parent_git_remote_branch,
                       parent_fetch_state_ref, parent_children_tuple_ref_list, last_pushed_git_svn_commit_hash,
                       is_parent_git_local_refspec_token_exist, has_parent_merge_commit, parent_git_svn_trunk_first_commit_hash,
                       child_read_tree_merge_commit_tuple_list, retain_commit_git_svn_parents,
                       reuse_commit_author_date_time, reuse_commit_message, reuse_commit_message_refspec_token_or_commit_hash,
                       git_svn_params_dict):
  # CAUTION:
  #   Reimplementation based on:
  #   https://stackoverflow.com/questions/59702488/git-merge-multiple-commits-into-one-in-an-orphan-branch-each-commit-in-a-prefix/59707222#59707222
  #

  # Start merge a commit w/o commit it through a direct read/write to the source tree.
  #

  call_git(['read-tree', '--empty'])

  # CAUTION:
  #   We must collect all merge commits into a dictionary to accumulate all merge commits for a particular prefix to apply them in one single `git read-tree` command,
  #   otherwise they would not be merged and a next call to the command with a particular prefix would replace the prefix content of a previous call.
  #
  read_tree_prefix_to_merge_commit_hash_list_dict = {}
  commit_tree_parent_merge_commit_hash_list = []

  # Collect previously pushed parent repository commit.
  #

  git_append_read_tree_merge_commit_hash_to_prefix_dict(read_tree_prefix_to_merge_commit_hash_list_dict, '', last_pushed_git_svn_commit_hash)

  # Collect a parent git-svn commit.
  #

  if has_parent_merge_commit:
    git_append_read_tree_merge_commit_hash_to_prefix_dict(read_tree_prefix_to_merge_commit_hash_list_dict, '', parent_git_svn_trunk_first_commit_hash)

  # Collect the rest merge commits.
  #

  for prefix, refspec_or_commit_hash in child_read_tree_merge_commit_tuple_list:
    git_append_read_tree_merge_commit_hash_to_prefix_dict(read_tree_prefix_to_merge_commit_hash_list_dict, prefix, refspec_or_commit_hash)

  # Merge all collected merge commits in sorted by prefix order beginning from the root prefix.
  #

  for merge_commit_prefix, merge_commit_hash_list in sorted(read_tree_prefix_to_merge_commit_hash_list_dict.items()):
    if merge_commit_prefix != '':
      # WORKAROUND:
      #   To workaround an issue with the error message `error: Entry '<prefix>/...' overlaps with '<prefix>/...'.  Cannot bind.`
      #   we have to entirely remove the prefix directory from the working copy at first!
      #   Based on: `git read-tree failure` : https://groups.google.com/d/msg/git-users/l0BKlv0EFKw/AvFEFXgX6vMJ
      #
      call_git_no_except(['rm', '--cached', '-r', merge_commit_prefix])

      call_git(['read-tree', '--prefix=' + merge_commit_prefix] + [merge_commit_hash for merge_commit_hash in merge_commit_hash_list])
    else:
      call_git(['read-tree'] + [merge_commit_hash for merge_commit_hash in merge_commit_hash_list])

    for merge_commit_hash in merge_commit_hash_list:
      if merge_commit_hash != parent_git_svn_trunk_first_commit_hash or retain_commit_git_svn_parents:
        commit_tree_parent_merge_commit_hash_list.append(merge_commit_hash)

  # Create a tree object from the local index.
  #

  ret = call_git(['write-tree'])
  merge_tree_hash = ret[1].strip()

  # Commit the local index with the mainline commit message reuse.
  #

  # Change and make a commit:
  #   1. Author name and email.
  #   2. Commit author date.
  #
  call_env = {
    'GIT_AUTHOR_NAME' : yaml_expand_global_string('${${SCM_TOKEN}.USER}'),
    'GIT_AUTHOR_EMAIL': yaml_expand_global_string('${${SCM_TOKEN}.EMAIL}'),
    'GIT_AUTHOR_DATE' : reuse_commit_author_date_time
  }

  if reuse_commit_message is None:
    ret = call_git(['log', '--max-count=1', '--format=%B', reuse_commit_message_refspec_token_or_commit_hash])
    reuse_commit_message = ret[1].rstrip()

  # `-C` parameter exists only in the `git commit` command
  """
    ret = call_git(['commit-tree', merge_tree_hash] +
      [j for i in [('-p', merge_commit_hash) for merge_commit_hash in commit_tree_parent_merge_commit_hash_list] for j in i] +
      ['-C', reuse_commit_message_refspec_token_or_commit_hash],
      env = call_env)
  """

  # CAUTION:
  #   Use `w+b` instead of `w+t` to avoid silent line endings convertion.
  #
  with tkl.TmpFileIO('w+b') as stdin_iostr:
    stdin_iostr.write(reuse_commit_message.encode('utf-8'))
    stdin_iostr.flush() # otherwise would be an empty commit message
    # WORKAROUND:
    #   Temporary workwound, based on:
    #   `plumbum.local['...'].run(stdin = myobj)` ignores stdin as a not empty temporary file` : https://github.com/tomerfiliba/plumbum/issues/487
    #
    with open(stdin_iostr.path, 'rt') as stdin_file:
      ret = call_git(['commit-tree', merge_tree_hash] +
        [j for i in [('-p', merge_commit_hash) for merge_commit_hash in commit_tree_parent_merge_commit_hash_list] for j in i] +
        ['-F', '-'], stdin = stdin_file, env = call_env)

  merge_commmit_hash = ret[1].strip()

  parent_git_local_refspec_token = get_git_local_refspec_token(parent_git_local_branch, parent_git_remote_branch)
  parent_git_remote_refspec_token = get_git_remote_refspec_token(parent_remote_name, parent_git_local_branch, parent_git_remote_branch)

  # update branch and switch on it
  if is_parent_git_local_refspec_token_exist:
    call_git(['update-ref', parent_git_local_refspec_token, merge_commmit_hash])

    call_git(['switch', '--no-guess', parent_git_local_branch])
  else:
    call_git(['switch', '-c', parent_git_local_branch, merge_commmit_hash])

  parent_git_push_refspec_token = get_git_push_refspec_token(parent_git_local_branch, parent_git_remote_branch)

  is_parent_first_time_push = parent_fetch_state_ref['is_first_time_push']
  if not is_parent_first_time_push:
    call_git(['push', parent_remote_name, parent_git_push_refspec_token])
  else:
    call_git(['push', '-u', parent_remote_name, parent_git_push_refspec_token])
    parent_fetch_state_ref['is_first_time_push'] = False

  git_log_depth = get_default_git_log_root_depth() + git_svn_params_dict['git_log_list_child_max_depth_fetch']

  ret = call_git(['log', '--max-count=' + str(git_log_depth),
    '--format=' + get_default_git_log_format(), parent_git_remote_refspec_token],
    max_stdout_lines = 16)

  last_pushed_git_svn_commit_rev, \
  last_pushed_git_svn_commit_hash, \
  last_pushed_git_svn_commit_author_timestamp, last_pushed_git_svn_commit_author_date_time, \
  last_pushed_git_svn_commit_commit_timestamp, last_pushed_git_svn_commit_commit_date_time, last_pushed_num_git_commits, \
  last_git_svn_commit_hash, \
  last_git_svn_commit_author_timestamp, last_git_svn_commit_author_date_time, \
  last_git_svn_commit_commit_timestamp, last_git_svn_commit_commit_date_time, last_pushed_num_git_commits = \
    get_first_or_last_git_svn_commit_from_git_log(ret[1].strip(), parent_svn_reporoot, parent_svn_path_prefix,
      continue_search_svn_rev = True)

  if last_pushed_git_svn_commit_hash != merge_commmit_hash:
    raise Exception('fetch-merge-push sequence is corrupted, last pushed commit hash is not what was before the push')

  # update last pushed git/svn commit
  parent_fetch_state_ref['last_pushed_git_svn_commit'] = (
    last_pushed_git_svn_commit_rev, last_pushed_git_svn_commit_hash,
    last_pushed_git_svn_commit_author_timestamp, last_pushed_git_svn_commit_author_date_time,
    last_pushed_git_svn_commit_commit_timestamp, last_pushed_git_svn_commit_commit_date_time
  )

def git_svn_compare_commits(configure_dir, scm_token, remote_name, svn_rev,
                            git_subtrees_root = None, svn_subtrees_root = None,
                            reset_hard = False, cleanup = False,
                            update_svn_repo_uuid = False, verbosity = 0):
  print("git_svn_compare_commits: {0}".format(configure_dir))

  set_verbosity_level(verbosity)

  if not git_subtrees_root is None:
    print(' * git_subtrees_root: `' + git_subtrees_root + '`')

  svn_rev = int(svn_rev)

  if configure_dir == '':
    print_err("{0}: error: configure directory is not defined.".format(sys.argv[0]))
    return 1

  if configure_dir[-1:] in ['\\', '/']:
    configure_dir = configure_dir[:-1]

  if not os.path.isdir(configure_dir):
    print_err("{0}: error: configure directory does not exist: `{1}`.".format(sys.argv[0], configure_dir))
    return 32

  if not git_subtrees_root is None and not os.path.isdir(git_subtrees_root):
    print_err("{0}: error: git subtrees root directory does not exist: git_subtrees_root=`{1}`.".format(sys.argv[0], git_subtrees_root))
    return 33

  if not svn_subtrees_root is None and not os.path.isdir(svn_subtrees_root):
    print_err("{0}: error: svn subtrees root directory does not exist: svn_subtrees_root=`{1}`.".format(sys.argv[0], svn_subtrees_root))
    return 34

  wcroot_dir = getglobalvar(scm_token + '.WCROOT_DIR')
  if wcroot_dir == '': return -254
  if WCROOT_OFFSET == '': return -253

  wcroot_path = os.path.abspath(os.path.join(WCROOT_OFFSET, wcroot_dir)).replace('\\', '/')

  git_user = getglobalvar(scm_token + '.USER')
  git_email = getglobalvar(scm_token + '.EMAIL')

  if not os.path.exists(wcroot_path):
    os.mkdir(wcroot_path)

  with local_cwd(' ->> cwd: `{0}`...', ' -<< cwd: `{0}`...', wcroot_path), \
       GitReposListReader(configure_dir + '/git_repos.lst') as git_repos_reader, ServiceProcCache() as svc_proc_cache:
    executed_procs = cache_init_service_proc(svc_proc_cache)

    with tkl.OnExit(lambda: cache_close_running_procs(executed_procs, svc_proc_cache)):
      column_names, column_widths = get_git_svn_repos_list_table_params()

      if git_subtrees_root is None:
        git_subtrees_root = wcroot_path + '/.git/.pyxvcs/gitwc'

      git_svn_repo_tree_dict, git_svn_repo_tree_tuple_ref_preorder_list, svn_repo_root_to_uuid_dict, git_svn_params_dict = \
        read_git_svn_repo_list(git_repos_reader, scm_token, wcroot_path, git_subtrees_root, column_names, column_widths,
          update_svn_repo_uuid = update_svn_repo_uuid)

      if not remote_name is None:
        is_remote_name_found = False

        for git_svn_repo_tree_tuple_ref in git_svn_repo_tree_tuple_ref_preorder_list:
          repo_params_ref = git_svn_repo_tree_tuple_ref[0]

          if repo_params_ref['remote_name'] == remote_name:
            is_remote_name_found = True
            break

        if not is_remote_name_found:
          raise Exception('remote name is not found: scm_token={0} remote_name={1}'.format(scm_token, remote_name))

        parent_tuple_ref = repo_params_ref['parent_tuple_ref']
      else:
        # use the root by default
        for git_svn_repo_tree_tuple_ref in git_svn_repo_tree_tuple_ref_preorder_list:
          repo_params_ref = git_svn_repo_tree_tuple_ref[0]

          parent_tuple_ref = repo_params_ref['parent_tuple_ref']
          if parent_tuple_ref is None:
            break

      ordinal_index_prefix_str = repo_params_ref['ordinal_index_prefix_str']

      remote_name = repo_params_ref['remote_name']

      git_reporoot = repo_params_ref['git_reporoot']
      svn_reporoot = repo_params_ref['svn_reporoot']

      parent_git_path_prefix = repo_params_ref['parent_git_path_prefix']
      git_path_prefix = repo_params_ref['git_path_prefix']
      svn_path_prefix = repo_params_ref['svn_path_prefix']

      git_local_branch = repo_params_ref['git_local_branch']
      git_remote_branch = repo_params_ref['git_remote_branch']

      if not parent_tuple_ref is None:
        subtree_git_wcroot = repo_params_ref['git_wcroot']

      svn_repopath = svn_reporoot + (('/' + svn_path_prefix) if svn_path_prefix != '' else '')

      with conditional(not parent_tuple_ref is None,
                       local_cwd(' ->> cwd: `{0}`...', ' -<< cwd: `{0}`...', subtree_git_wcroot) if not parent_tuple_ref is None else None):
        print('- GIT searching...')

        git_local_refspec_token = get_git_local_refspec_token(git_local_branch, git_remote_branch)
        git_remote_refspec_token = get_git_remote_refspec_token(remote_name, git_local_branch, git_remote_branch)

        if not svn_rev is None:
          # find a particular svn commit revision when a revision number is defined
          git_last_svn_rev, git_commit_hash, \
          git_commit_author_timestamp, git_commit_author_date_time, \
          git_commit_commit_timestamp, git_commit_commit_date_time, \
          num_overall_git_commits, \
          git_svn_commit_fetch_timestamp = \
            get_last_git_svn_commit_by_git_log(git_remote_refspec_token, svn_reporoot, svn_path_prefix, git_path_prefix,
              svn_rev, git_svn_params_dict)
        else:
          # find the last svn commit revision when a revision number is not defined
          git_last_svn_rev, git_commit_hash, \
          git_commit_author_timestamp, git_commit_author_date_time, \
          git_commit_commit_timestamp, git_commit_commit_date_time, \
          num_overall_git_commits, \
          git_svn_commit_fetch_timestamp = \
            get_last_git_svn_rev_by_git_log(git_remote_refspec_token, svn_reporoot, svn_path_prefix, git_path_prefix,
              git_svn_params_dict)

        if not git_last_svn_rev > 0 and num_overall_git_commits > 0:
          raise Exception('svn revision is not found in the git log output: svn_rev={0} svn_repopath=`{1}`'.
            format(git_last_svn_rev, svn_repopath))

        print('- GIT checkouting...')

        # CAUTION:
        #   1. The index file cleanup is required here to avoid the error messsage:
        #      `fatal: cannot switch branch while merging`
        #   2. The Working Copy cleanup is required together with the index file cleanup to avoid later a problem with a
        #      merge around untracked files with the error message:
        #      `error: The following untracked working tree files would be overwritten by merge`
        #      `Please move or remove them before you merge.`.
        #   3. We have to cleanup the HEAD instead of the local branch.
        #
        if reset_hard:
          call_git(['reset', '--hard'])
        """
        else:
          call_git(['reset', '--mixed'])
        """

        # cleanup the untracked files if were left behind, for example, by the previous `git reset --mixed`
        if cleanup:
          call_git(['clean', '-d', '-f'])

        # CAUTION:
        #   The HEAD reference still can be not initialized after the `git switch ...` command.
        #   We have to try to initialize it from here.
        #
        call_git(['checkout', '--no-guess', git_commit_hash])

      if svn_subtrees_root is None:
        svn_subtrees_root = wcroot_path + '/.git/.pyxvcs/svnwc'

      subtree_svn_dir = remote_name + "'" + svn_path_prefix.replace('/', '--')
      subtree_svn_wcroot = os.path.abspath(os.path.join(svn_subtrees_root, subtree_svn_dir)).replace('\\', '/')

      if not os.path.exists(subtree_svn_wcroot):
        print('>mkdir: -p ' + subtree_svn_wcroot)
        try:
          os.makedirs(subtree_svn_wcroot)
        except FileExistsError:
          pass

      with local_cwd(' ->> cwd: `{0}`...', ' -<< cwd: `{0}`...', subtree_svn_wcroot):
        print('- SVN checkouting...')

        if not os.path.exists('.svn'):
          # shift current directory up to make svn checkout
          with local_cwd(' ->> cwd: `{0}`...', ' -<< cwd: `{0}`...', '..'):
            call_svn(['co', '-r' + str(git_last_svn_rev), '--ignore-externals', svn_repopath, subtree_svn_dir])
        else:
          # shift current directory up to show the subdirectory
          with local_cwd(' ->> cwd: `{0}`...', ' -<< cwd: `{0}`...', '..'):
            call_svn(['up', '-r' + str(git_last_svn_rev), '--ignore-externals', subtree_svn_dir])

      print('- GIT-SVN comparing...')
