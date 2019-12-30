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

import os, sys, io, csv, shlex, copy, re, shutil
from plumbum import local
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
  #   The `git switch --no-guess -c ...` still can guess and create not empty
  #   branch with a commit or commits. Have to use it with the `--orphan` to
  #   supress that behaviour.
  #
  call_git(['switch', '--orphan', git_local_branch])

def git_register_remotes(git_repos_reader, scm_token, remote_name, with_root):
  git_repos_reader.reset()

  if with_root:
    for root_row in git_repos_reader:
      if root_row['scm_token'] == scm_token and root_row['remote_name'] == remote_name:
        root_remote_name = root_row['remote_name']
        root_git_reporoot = yaml_expand_global_string(root_row['git_reporoot'])

        ret = call_git_no_except(['remote', 'get-url', root_remote_name])
        if not ret[0]:
          call_git(['remote', 'set-url', root_remote_name, root_git_reporoot])
        else:
          git_remote_add_cmdline = root_row['git_remote_add_cmdline']
          if git_remote_add_cmdline == '.':
            git_remote_add_cmdline = ''
          else:
            git_remote_add_cmdline = yaml_expand_global_string(git_remote_add_cmdline)
          call_git(['remote', 'add', root_remote_name, root_git_reporoot] + shlex.split(git_remote_add_cmdline))
        break

    git_repos_reader.reset()

  for subtree_row in git_repos_reader:
    if subtree_row['scm_token'] == scm_token and subtree_row['parent_remote_name'] == remote_name:
      subtree_remote_name = subtree_row['remote_name']
      subtree_git_reporoot = yaml_expand_global_string(subtree_row['git_reporoot'])

      ret = call_git_no_except(['remote', 'get-url', subtree_remote_name])
      if not ret[0]:
        call_git(['remote', 'set-url', subtree_remote_name, subtree_git_reporoot])
      else:
        git_remote_add_cmdline = subtree_row['git_remote_add_cmdline']
        if git_remote_add_cmdline == '.':
          git_remote_add_cmdline = ''
        else:
          git_remote_add_cmdline = yaml_expand_global_string(git_remote_add_cmdline)
        call_git(['remote', 'add', subtree_remote_name, subtree_git_reporoot] + shlex.split(git_remote_add_cmdline))

def git_get_local_branch_refspec_list(regex_match_str = None):
  refspec_list = []

  ret = call_git(['branch', '-l', '--format', '%(refname)'])

  # To iterate over lines instead chars.
  # (see details: https://stackoverflow.com/questions/3054604/iterate-over-the-lines-of-a-string/3054898#3054898 )

  stdout_lines = io.StringIO(ret[1].rstrip())
  for line in stdout_lines:
    line = line.rstrip()
    if regex_match_str is None:
      is_matched = True
    else:
      is_matched = True if re.match(regex_match_str, line) else False
    if is_matched:
      refspec_list.append(line)

  return refspec_list if len(refspec_list) > 0 else None

def git_fetch_child_subtree_merge_branches(children_tuple_ref_list):
  for children_tuple_ref in children_tuple_ref_list:
    child_repo_params_ref = children_tuple_ref[0]
    child_fetch_state_ref = children_tuple_ref[1]

    child_last_pushed_git_svn_commit = child_fetch_state_ref['last_pushed_git_svn_commit']
    child_last_pushed_git_svn_commit_rev = child_last_pushed_git_svn_commit[0]

    if not child_last_pushed_git_svn_commit_rev > 0:
      continue

    subtree_remote_name = child_repo_params_ref['remote_name']

    subtree_git_reporoot = yaml_expand_global_string(child_repo_params_ref['git_reporoot'])
    subtree_git_local_branch = yaml_expand_global_string(child_repo_params_ref['git_local_branch'])
    subtree_git_remote_branch = yaml_expand_global_string(child_repo_params_ref['git_remote_branch'])

    subtree_parent_git_path_prefix = child_repo_params_ref['parent_git_path_prefix']

    child_last_pushed_git_svn_commit_hash = child_last_pushed_git_svn_commit[1]

    if subtree_parent_git_path_prefix == '.':
      raise Exception('not root branch type must have not empty git parent path prefix')

    # expand if contains a variable substitution
    subtree_parent_git_path_prefix = yaml_expand_global_string(subtree_parent_git_path_prefix)

    # CAUTION:
    #   We can not simply call to `git subtree add ...` here as long as it would return `prefix '...' already exists` error.
    #   Instead we must take changes into a separate branch and merge them into main branch, for example, like introduced here:
    #   https://stackoverflow.com/questions/17842966/how-can-i-create-a-gitsubtree-of-an-existing-repository/27432237#27432237
    #

    subtree_local_tmp_branch = subtree_remote_name + '--subtree'

    # cleanup through remove entire branch
    call_git_no_except(['branch', '-D', subtree_local_tmp_branch])

    subtree_git_remote_refspec_token, subtree_git_remote_local_refspec_token = \
      get_git_remote_refspec_token_tuple(subtree_remote_name, subtree_git_local_branch, subtree_git_remote_branch)

    # get last pushed commit hash
    subtree_git_last_pushed_commit_hash = get_git_last_pushed_commit_hash(subtree_git_reporoot, subtree_git_remote_local_refspec_token)

    if not subtree_git_last_pushed_commit_hash is None:
      # fetch remote branch into temporary local branch
      subtree_remote_branch = validate_git_refspec(subtree_git_local_branch, subtree_git_remote_branch)[1]

      call_git(['fetch', subtree_remote_name, subtree_remote_branch + ':refs/heads/' + subtree_local_tmp_branch])

def git_remove_child_subtree_merge_branches(children_tuple_ref_list):
  for children_tuple_ref in children_tuple_ref_list:
    child_repo_params_ref = children_tuple_ref[0]

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

  for row in io.StringIO(ret[1].rstrip()):
    first_commit_hash = row.rstrip()
    break

  return first_commit_hash.strip()
"""

# Returns only the first git commit parameters or nothing.
#
def get_git_first_commit_from_git_log(str):
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
      if not commit_hash is None:
        # return the previous one
        return (commit_svn_rev, commit_hash, author_timestamp, author_date_time, commit_timestamp, commit_date_time)
      commit_hash = value_list[1]
    elif key == 'timestamp':
      timestamp_list = value_list[1].split('|')
      author_timestamp = int(timestamp_list[0])
      commit_timestamp = int(timestamp_list[1])
    elif key == 'date_time':
      date_time_list = value_list[1].split('|')
      author_date_time = date_time_list[0]
      commit_date_time = date_time_list[1]
    elif key == 'git-svn-id':
      git_svn_url = value_list[1].split(' ', 1)[0]
      commit_svn_rev_index = git_svn_url.rfind('@')
      if commit_svn_rev_index > 0:
        svn_path = git_svn_url[:commit_svn_rev_index]
        commit_svn_rev = int(git_svn_url[commit_svn_rev_index + 1:])

  return (commit_svn_rev, commit_hash, author_timestamp, author_date_time, commit_timestamp, commit_date_time)

# Returns the git commit where was found a svn revision under the requested remote svn url,
# otherwise would return partially the last commit parameters.
#
def get_git_commit_from_git_log(str, svn_reporoot, svn_path_prefix):
  if svn_path_prefix == '.': svn_path_prefix = ''

  svn_remote_path = svn_reporoot + ('/' + svn_path_prefix if svn_path_prefix != '' else '')

  commit_svn_rev = 0
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
    elif key == 'git-svn-id':
      git_svn_url = value_list[1].split(' ', 1)[0]
      commit_svn_rev_index = git_svn_url.rfind('@')
      if commit_svn_rev_index > 0:
        svn_path = git_svn_url[:commit_svn_rev_index]
        commit_svn_rev = int(git_svn_url[commit_svn_rev_index + 1:])

        svn_path_wo_scheme = tkl.ParseResult('', *tkl.urlparse(svn_path)[1:]).geturl()
        svn_remote_path_wo_scheme = tkl.ParseResult('', *tkl.urlparse(svn_remote_path)[1:]).geturl()

        if svn_path_wo_scheme == svn_remote_path_wo_scheme:
          return (commit_svn_rev, commit_hash, author_timestamp, author_date_time, commit_timestamp, commit_date_time, num_commits)

  # if not found then timestamp is the last commit timestamp
  return (0, None, author_timestamp, author_date_time, commit_timestamp, commit_date_time, num_commits)

# Returns the git commit list where was found all svn revisions under the requested remote svn url.
#
def get_git_commit_list_from_git_log(str, svn_reporoot, svn_path_prefix):
  if svn_path_prefix == '.': svn_path_prefix = ''

  svn_remote_path = svn_reporoot + ('/' + svn_path_prefix if svn_path_prefix != '' else '')

  commit_list = []

  commit_svn_rev = 0
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
    elif key == 'git-svn-id':
      git_svn_url = value_list[1].split(' ', 1)[0]
      commit_svn_rev_index = git_svn_url.rfind('@')
      if commit_svn_rev_index > 0:
        svn_path = git_svn_url[:commit_svn_rev_index]
        commit_svn_rev = int(git_svn_url[commit_svn_rev_index + 1:])

        svn_path_wo_scheme = tkl.ParseResult('', *tkl.urlparse(svn_path)[1:]).geturl()
        svn_remote_path_wo_scheme = tkl.ParseResult('', *tkl.urlparse(svn_remote_path)[1:]).geturl()

        if svn_path_wo_scheme == svn_remote_path_wo_scheme:
          commit_list.append((commit_svn_rev, commit_hash, author_timestamp, author_date_time, commit_timestamp, commit_date_time))

  return (commit_list if len(commit_list) > 0 else None, num_commits)

def get_git_last_pushed_commit_hash(git_reporoot, git_remote_local_refspec_token):
  git_last_pushed_commit_hash = None

  ret = call_git(['ls-remote', git_reporoot])

  with GitLsRemoteListReader(ret[1].rstrip()) as git_ls_remote_reader:
    for row in git_ls_remote_reader:
      if row['ref'] == git_remote_local_refspec_token:
        git_last_pushed_commit_hash = row['hash']
        break

  return git_last_pushed_commit_hash

def get_git_local_head_commit_hash(git_local_refspec_token, no_except = False, verify_ref = True):
  git_local_head_commit_hash = None

  ret = call_git(['show-ref'] + (['--verify'] if verify_ref else []) + [git_local_refspec_token], no_except = no_except)

  with GitShowRefListReader(ret[1].rstrip()) as git_show_ref_reader:
    for row in git_show_ref_reader:
      if row['ref'] == git_local_refspec_token:
        git_local_head_commit_hash = row['hash'].rstrip()
        break

  if not git_local_head_commit_hash is None:
    print(git_local_head_commit_hash)

  return git_local_head_commit_hash

def get_git_remote_head_commit_hash(git_remote_refspec_token, no_except = False, verify_ref = True):
  git_remote_head_commit_hash = None

  ret = call_git(['show-ref'] + (['--verify'] if verify_ref else []) + [git_remote_refspec_token], no_except = no_except)

  with GitShowRefListReader(ret[1].rstrip()) as git_show_ref_reader:
    for row in git_show_ref_reader:
      if row['ref'] == git_remote_refspec_token:
        git_remote_head_commit_hash = row['hash'].rstrip()
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

  """
  # Drop all other references which might be created by a previous bad `git svn fetch ...` call except of the main local and the main remote references.
  # Description:
  #   The `git svn fetch ...` have has an ability to create a dangled HEAD reference which is assited with one more remote reference additionally
  #   to the already existed, so we must not just reassign the HEAD reference back to the FETCH_HEAD, but remove an added remote reference too.
  #   To do so we remove all the references returned by the `git show-ref` command except the main local and the main remote reference.
  #
  ret = call_git(['show-ref'])

  is_ref_list_updated = False

  with GitShowRefListReader(ret[1].rstrip()) as git_show_ref_reader:
    for row in git_show_ref_reader:
      ref = row['ref']
      if ref != git_local_refspec_token and ref != git_remote_refspec_token:
        # delete the reference
        call_git(['update-ref', '-d', ref])
        is_ref_list_updated = True
  """

def git_svn_fetch(git_svn_fetch_rev, last_pushed_git_svn_commit_rev, git_svn_fetch_cmdline_list,
                  remote_name, git_local_branch,
                  git_local_refspec_token, git_remote_refspec_token, last_pruned_git_svn_commit_dict,
                  prune_empty_git_svn_commits, single_rev = False):
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
      prev_head_refspec_token = ret[1].rstrip()
      prev_head_git_commit_hash = get_git_local_head_commit_hash(prev_head_refspec_token, no_except = True)

      if prev_head_git_commit_hash is None:
        # WORKAROUND:
        #   To workaround an issue with the error message
        #   `Ref 'refs/remotes/<remote_name>/git-svn-trunk' was deleted`
        #   `fatal: Not a valid object name HEAD`
        #   we have to temporary assign the local branch to the remote branch.
        #
        call_git(['switch', '--no-guess', '-c', git_local_branch, git_svn_trunk_remote_refspec_token])

        """
        # update HEAD reference to the git-svn branch
        call_git(['symbolic-ref', 'HEAD', git_local_refspec_token])

        # reset the file index and the working copy
        call_git(['reset', '--hard', git_svn_trunk_remote_refspec_token])
        """

      if not last_pruned_git_svn_commit_hash is None:
        call_git(['filter-branch', '--prune-empty', last_pruned_git_svn_commit_hash + '..' + git_svn_trunk_remote_refspec_token],
          env = {'FILTER_BRANCH_SQUELCH_WARNING' : 1})
      else:
        call_git(['filter-branch', '--prune-empty', git_svn_trunk_remote_refspec_token],
          env = {'FILTER_BRANCH_SQUELCH_WARNING' : 1})

      next_pruned_git_svn_commit_hash = get_git_remote_head_commit_hash(git_svn_trunk_remote_refspec_token, no_except = True)

      if prev_head_git_commit_hash is None:
        """
        if not next_pruned_git_svn_commit_hash is None:
          if last_fetched_git_svn_commit_hash != next_pruned_git_svn_commit_hash:
            # reset the file index and the working copy
            call_git(['reset', '--hard', git_svn_trunk_remote_refspec_token])

          # detach HEAD
          call_git_no_except(['checkout', '--detach'])
        """

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
    if subtree_row['scm_token'] == scm_token and subtree_row['parent_remote_name'] == remote_name:
      child_svn_reporoot_urlpath = tkl.ParseResult('', *tkl.urlparse(yaml_expand_global_string(subtree_row['svn_reporoot']))[1:]).geturl()
      if child_svn_reporoot_urlpath == parent_svn_reporoot_urlpath:
        collected_subtree_svn_path_prefixes.add(yaml_expand_global_string(subtree_row['svn_path_prefix']))

  git_repos_reader.reset()

  # collects the rest paths with different repository roots

  parent_svn_path_prefix = ''
  for subtree_row in git_repos_reader:
    if subtree_row['scm_token'] == scm_token and subtree_row['remote_name'] == remote_name:
      parent_svn_path_prefix = yaml_expand_global_string(subtree_row['svn_path_prefix'])
      break

  git_repos_reader.reset()

  for subtree_row in git_repos_reader:
    if subtree_row['scm_token'] == scm_token and subtree_row['parent_remote_name'] == remote_name:
      collected_subtree_svn_path_prefixes.add(parent_svn_path_prefix + '/' + yaml_expand_global_string(subtree_row['parent_git_path_prefix']))

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

  for children_tuple_ref in children_tuple_ref_list:
    child_repo_params_ref = children_tuple_ref[0]

    child_svn_reporoot = child_repo_params_ref['svn_reporoot']

    child_svn_reporoot_urlpath = tkl.ParseResult('', *tkl.urlparse(child_svn_reporoot)[1:]).geturl()
    if child_svn_reporoot_urlpath == parent_svn_reporoot_urlpath:
      child_svn_path_prefix = child_repo_params_ref['svn_path_prefix']

      collected_subtree_svn_path_prefixes.add(child_svn_path_prefix)

  # collects the rest paths with different repository roots

  parent_svn_path_prefix = parent_repo_params_ref['svn_path_prefix']

  for children_tuple_ref in children_tuple_ref_list:
    child_repo_params_ref = children_tuple_ref[0]

    child_parent_git_path_prefix = child_repo_params_ref['parent_git_path_prefix']

    collected_subtree_svn_path_prefixes.add(parent_svn_path_prefix + '/' + child_parent_git_path_prefix)

  # generate `--ignore-paths` string from collected paths

  subtree_git_svn_ignore_paths_regex = ''

  for subtree_svn_path_prefix in collected_subtree_svn_path_prefixes:
    subtree_git_svn_path_prefix_regex = get_git_svn_path_prefix_regex(subtree_svn_path_prefix)
    subtree_git_svn_ignore_paths_regex += ('|' if len(subtree_git_svn_ignore_paths_regex) > 0 else '') + subtree_git_svn_path_prefix_regex

  return subtree_git_svn_ignore_paths_regex

# returns as tuple:
#   git_last_svn_rev          - last pushed svn revision if has any
#   git_commit_hash           - git commit associated with the last pushed svn revision if has any, otherwise the last git commit
#   git_author_timestamp      - git author timestamp of the `git_commit_hash` commit
#   git_author_date_time      - git author datetime of the `git_commit_hash` commit
#   git_commit_timestamp      - git commit timestamp of the `git_commit_hash` commit
#   git_commit_date_time      - git commit datetime of the `git_commit_hash` commit
#   num_overall_git_commits   - number of overall looked up commits from branch HEAD commit by the remote refspec token
#
def get_last_git_svn_rev_by_git_log(remote_name, git_local_branch, git_remote_branch, svn_reporoot, svn_path_prefix,
                                    git_log_start_depth = 16, except_on_max_num_git_commits_lookup = 16,
                                    git_log_format = 'commit: %H%ntimestamp: %at|%ct%ndate_time: %ai|%ci%nauthor: %an <%ae>%n%b'):
  git_log_prev_depth = -1
  git_log_next_depth = git_log_start_depth  # initial `git log` commits depth
  git_log_prev_num_commits = -1
  git_log_next_num_commits = 0

  git_log_next_depth_increase_count = 0
  git_log_next_depth_increase_max_count = 3

  # use `--until` argument to shift commits window
  git_from_commit_timestamp = None

  num_overall_git_commits = 0

  # 1. iterate to increase the `git log` depth (`--max-count`) in case of equal the first and the last commit timestamps
  # 2. iterate to shift the `git log` window using `--until` parameter
  while True:
    git_remote_refspec_token = get_git_remote_refspec_token(remote_name, git_local_branch, git_remote_branch)

    ret = call_git(['log', '--max-count=' + str(git_log_next_depth), '--format=' + git_log_format,
      git_remote_refspec_token] +
      (['--until', str(git_from_commit_timestamp)] if not git_from_commit_timestamp is None else []),
      max_stdout_lines = 16)

    git_last_svn_rev, git_commit_hash, \
    git_commit_author_timestamp, git_commit_author_date_time, \
    git_commit_timestamp, git_commit_date_time, \
    num_git_commits = \
      get_git_commit_from_git_log(ret[1], svn_reporoot, svn_path_prefix)

    # return if svn revision is found
    if git_last_svn_rev > 0:
      return (
        git_last_svn_rev, git_commit_hash,
        git_commit_author_timestamp, git_commit_author_date_time,
        git_commit_timestamp, git_commit_date_time,
        num_overall_git_commits + num_git_commits
      )

    git_log_prev_num_commits = git_log_next_num_commits
    git_log_next_num_commits = num_git_commits

    # the `git log` depth can not be any longer increased (the `git log` list end)
    if git_log_next_depth > git_log_prev_depth and git_log_prev_num_commits >= git_log_next_num_commits:
      num_overall_git_commits += num_git_commits - 1
      break

    git_log_prev_depth = git_log_next_depth

    git_first_commit_svn_rev, git_first_commit_hash, \
    git_first_commit_author_timestamp, git_first_commit_author_date_time, \
    git_first_commit_timestamp, git_first_commit_date_time = \
      get_git_first_commit_from_git_log(ret[1].rstrip())

    # increase the depth of the `git log` if the last commit timestamp is not less than the first commit timestamp
    if git_commit_timestamp is None or git_commit_timestamp == git_first_commit_timestamp:
      git_log_next_depth_increase_count += 1
      if git_log_next_depth_increase_max_count < git_log_next_depth_increase_count:
        raise Exception('git log frame size is increased too many times: path=`{0}`'.format(svn_reporoot + '/' + svn_path_prefix))

      git_log_next_depth *= 2
      if git_from_commit_timestamp is None:
        git_from_commit_timestamp = git_first_commit_timestamp
    else:
      # update conditions
      git_log_prev_num_commits = -1
      git_from_commit_timestamp = git_commit_timestamp

      num_overall_git_commits += num_git_commits - 1

    if not except_on_max_num_git_commits_lookup is None and except_on_max_num_git_commits_lookup < num_overall_git_commits + 1:
      raise Exception('maximal commits lookup limit is reached: path=`{0}` commits={1} max={2}'.format(
        svn_reporoot + '/' + svn_path_prefix, num_overall_git_commits + 1, except_on_max_num_git_commits_lookup))

  return (0, None, None, None, None, None, num_overall_git_commits + 1)

# returns as tuple:
#   git_last_svn_rev          - last svn revision if has any
#   git_commit_hash           - git commit associated with the last svn revision if has any, otherwise the last git commit
#   git_author_timestamp      - git author timestamp of the `git_commit_hash` commit
#   git_author_date_time      - git author datetime of the `git_commit_hash` commit
#   git_commit_timestamp      - git commit timestamp of the `git_commit_hash` commit
#   git_commit_date_time      - git commit datetime of the `git_commit_hash` commit
#   num_overall_git_commits   - number of overall looked up commits from branch HEAD commit by the remote refspec token
#
def get_last_git_svn_commit_by_git_log(remote_name, git_local_branch, git_remote_branch, svn_reporoot, svn_path_prefix, svn_rev,
                                       git_log_start_depth = 16,
                                       git_log_format = 'commit: %H%ntimestamp: %at|%ct%ndate_time: %ai|%ci%nauthor: %an <%ae>%n%b'):
  git_log_prev_depth = -1
  git_log_next_depth = git_log_start_depth  # initial `git log` commits depth
  git_log_prev_num_commits = -1
  git_log_next_num_commits = 0

  git_log_next_depth_increase_count = 0
  git_log_next_depth_increase_max_count = 3

  # use `--until` argument to shift commits window
  git_from_commit_timestamp = None

  num_overall_git_commits = 0

  # 1. iterate to increase the `git log` depth (`--max-count`) in case of equal the first and the last commit timestamps
  # 2. iterate to shift the `git log` window using `--until` parameter
  while True:
    git_remote_refspec_token = get_git_remote_refspec_token(remote_name, git_local_branch, git_remote_branch)

    ret = call_git(['log', '--max-count=' + str(git_log_next_depth), '--format=' + git_log_format,
      git_remote_refspec_token] +
      (['--until', str(git_from_commit_timestamp)] if not git_from_commit_timestamp is None else []),
      max_stdout_lines = 16)

    git_svn_commit_list, num_git_commits = \
      get_git_commit_list_from_git_log(ret[1], svn_reporoot, svn_path_prefix)

    # return if svn revision is found
    if not git_svn_commit_list is None:
      commit_index = 0

      for git_svn_commit in git_svn_commit_list:
        git_svn_commit_rev = git_svn_commit[0]
        if git_svn_commit_rev == svn_rev:
          return (*git_svn_commit, num_overall_git_commits + commit_index)
        elif git_svn_commit_rev < svn_rev:
          # if found revision is less than searching one, then return as not found
          return (0, None, None, None, None, None, num_overall_git_commits + commit_index)

        commit_index += 1

      git_commit_timestamp = git_svn_commit_list[-1][4] # a commit commit timestamp
    else:
      git_commit_timestamp = None

    git_log_prev_num_commits = git_log_next_num_commits
    git_log_next_num_commits = num_git_commits

    # the `git log` depth can not be any longer increased (the `git log` list end)
    if git_log_next_depth > git_log_prev_depth and git_log_prev_num_commits >= git_log_next_num_commits:
      num_overall_git_commits += num_git_commits - 1
      break

    git_log_prev_depth = git_log_next_depth

    git_first_commit_svn_rev, git_first_commit_hash, \
    git_first_commit_author_timestamp, git_first_commit_author_date_time, \
    git_first_commit_timestamp, git_first_commit_date_time = \
      get_git_first_commit_from_git_log(ret[1].rstrip())

    # increase the depth of the `git log` if the last commit timestamp is not less than the first commit timestamp
    if not git_commit_timestamp is None and git_commit_timestamp == git_first_commit_timestamp:
      git_log_next_depth_increase_count += 1
      if git_log_next_depth_increase_max_count < git_log_next_depth_increase_count:
        raise Exception('git log frame size is increased too many times: path=`{0}`'.format(svn_reporoot + '/' + svn_path_prefix))

      git_log_next_depth *= 2
      if git_from_commit_timestamp is None:
        git_from_commit_timestamp = git_first_commit_timestamp
    else:
      # update conditions
      git_log_prev_num_commits = -1
      git_from_commit_timestamp = git_commit_timestamp

      num_overall_git_commits += num_git_commits - 1

  return (0, None, None, None, None, None, num_overall_git_commits + 1)

def git_update_svn_config_refspecs(remote_name):
  ret = call_git_no_except(['config', 'svn-remote.svn.fetch'])
  if not ret[0]:
    svn_remote_fetch_refspec_token = ret[1].rstrip()
    if len(svn_remote_fetch_refspec_token) > 0:
      svn_remote_fetch_refspec_token = svn_remote_fetch_refspec_token.replace('refs/remotes/origin/trunk', get_git_svn_trunk_remote_refspec_token(remote_name))
      call_git(['config', 'svn-remote.svn.fetch', svn_remote_fetch_refspec_token])

  ret = call_git_no_except(['config', 'svn-remote.svn.branches'])
  if not ret[0]:
    svn_remote_branches_refspec_token = ret[1].rstrip()
    if len(svn_remote_branches_refspec_token) > 0:
      svn_remote_branches_refspec_token = svn_remote_branches_refspec_token.replace('refs/remotes/origin/*', get_git_svn_branches_remote_refspec_token(remote_name) + '/*')
      call_git(['config', 'svn-remote.svn.branches', svn_remote_branches_refspec_token])

  ret = call_git_no_except(['config', 'svn-remote.svn.tags'])
  if not ret[0]:
    svn_remote_tags_refspec_token = ret[1].rstrip()
    if len(svn_remote_tags_refspec_token) > 0:
      svn_remote_tags_refspec_token = svn_remote_tags_refspec_token.replace('refs/remotes/origin/tags/*', get_git_svn_tags_remote_refspec_token(remote_name) + '/*')
      call_git(['config', 'svn-remote.svn.tags', svn_remote_tags_refspec_token])


def git_init(configure_dir, scm_token, git_subtrees_root = None, root_only = False, verbosity = 0):
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

  print(' ->> wcroot: `{0}`'.format(wcroot_path))

  if not os.path.exists(wcroot_path):
    os.mkdir(wcroot_path)

  with local.cwd(wcroot_path), ServiceProcCache() as svc_proc_cache:
    executed_procs = cache_init_service_proc(svc_proc_cache)

    with tkl.OnExit(lambda: cache_close_running_procs(executed_procs, svc_proc_cache)):
      if not os.path.exists(wcroot_path + '/.git'):
        call_git(['init', wcroot_path])

      with GitReposListReader(configure_dir + '/git_repos.lst') as git_repos_reader:
        root_remote_name = None
        remote_name_list = []

        for row in git_repos_reader:
          if row['scm_token'] == scm_token and row['branch_type'] == 'root':
            root_remote_name = row['remote_name']
            remote_name_list.append(root_remote_name)

            root_svn_reporoot = yaml_expand_global_string(row['svn_reporoot'])
            root_svn_path_prefix = yaml_expand_global_string(row['svn_path_prefix'])
            root_git_svn_init_cmdline = row['git_svn_init_cmdline']
            if root_git_svn_init_cmdline == '.':
              root_git_svn_init_cmdline = ''
            else:
              root_git_svn_init_cmdline = yaml_expand_global_string(root_git_svn_init_cmdline)
            break

        if root_remote_name is None:
          raise Exception('the root record is not found in the git repositories list')

        root_git_svn_init_cmdline_list = shlex.split(root_git_svn_init_cmdline)

        # Always use the trunk, even if it is in a subdirectory, to later be able to use the SVN url always as a root url without relative suffix and
        # let the git to generate a commit hash based on a complete path from the SVN root.
        if '--stdlayout' not in root_git_svn_init_cmdline_list and '--trunk' not in root_git_svn_init_cmdline_list:
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
          root_svn_url_reg = ret[1].rstrip()
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

        is_builtin_git_subtrees_root = False
        if git_subtrees_root is None:
          git_subtrees_root = wcroot_path + '/.git/svn2git/gitwc'
          is_builtin_git_subtrees_root = True

        # Initialize non root git repositories as stanalone working copies inside the `git_subtrees_root` directory,
        # use the combination of the `remote_name` and the `parent_git_path_prefix` as a prefix to a working copy directory.

        git_repos_reader.reset()

        for subtree_row in git_repos_reader:
          if subtree_row['scm_token'] == scm_token and subtree_row['branch_type'] != 'root':
            subtree_parent_git_path_prefix = subtree_row['parent_git_path_prefix']

            if subtree_parent_git_path_prefix == '.':
              raise Exception('not root branch type must have not empty git parent path prefix')

            subtree_remote_name = subtree_row['remote_name']
            if subtree_remote_name in remote_name_list:
              raise Exception('remote_name must be unique in the repositories list for the same scm_token: remote_name=`{0}` scm_token=`{1}`'.
                format(subtree_remote_name, scm_token))

            subtree_parent_remote_name = subtree_row['parent_remote_name']
            if subtree_parent_remote_name not in remote_name_list:
              raise Exception('parent_remote_name must be declared as a remote name for the same scm_token: parent_remote_name=`{0}` scm_token=`{1}`'.
                format(subtree_parent_remote_name, scm_token))

            remote_name_list.append(subtree_remote_name)

            subtree_svn_reporoot = yaml_expand_global_string(subtree_row['svn_reporoot'])
            # expand if contains a variable substitution
            subtree_parent_git_path_prefix = yaml_expand_global_string(subtree_parent_git_path_prefix)
            subtree_svn_path_prefix = yaml_expand_global_string(subtree_row['svn_path_prefix'])

            subtree_git_svn_init_cmdline = subtree_row['git_svn_init_cmdline']
            if subtree_git_svn_init_cmdline == '.':
              subtree_git_svn_init_cmdline = ''
            else:
              subtree_git_svn_init_cmdline = yaml_expand_global_string(subtree_git_svn_init_cmdline)

            subtree_git_wcroot = os.path.abspath(os.path.join(git_subtrees_root, subtree_remote_name + "'" + subtree_parent_git_path_prefix.replace('/', '--'))).replace('\\', '/')

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

            print(' ->> cwd: `{0}`...'.format(subtree_git_wcroot))

            with local.cwd(subtree_git_wcroot):
              if not os.path.exists(subtree_git_wcroot + '/.git'):
                call_git(['init', subtree_git_wcroot])

              subtree_git_svn_init_cmdline_list = shlex.split(subtree_git_svn_init_cmdline)

              # Always use the trunk, even if it is in a subdirectory, to later be able to use the SVN url always as a root url without relative suffix and
              # let the git to generate a commit hash based on a complete path from the SVN root.
              if '--stdlayout' not in subtree_git_svn_init_cmdline_list and '--trunk' not in subtree_git_svn_init_cmdline_list:
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
                  subtree_svn_url_reg = ret[1].rstrip()
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
      text += ' '
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
      text += ' '
    text += (column_width * '-')

  print('  ' + text)

def read_git_svn_repo_list(git_repos_reader, scm_token, wcroot_path, git_subtrees_root, column_names, column_widths, update_svn_repo_uuid = True):
  print('- Reading GIT-SVN repositories list:')

  has_root = False

  git_repos_reader.reset()

  for row in git_repos_reader:
    if row['scm_token'] == scm_token and row['branch_type'] == 'root':
      has_root = True

      root_remote_name = row['remote_name']

      root_git_reporoot = yaml_expand_global_string(row['git_reporoot'])
      root_svn_reporoot = yaml_expand_global_string(row['svn_reporoot'])

      root_parent_git_path_prefix = yaml_expand_global_string(row['parent_git_path_prefix'])
      root_svn_path_prefix = yaml_expand_global_string(row['svn_path_prefix'])

      root_git_local_branch = yaml_expand_global_string(row['git_local_branch'])
      root_git_remote_branch = yaml_expand_global_string(row['git_remote_branch'])

      break

  if not has_root:
    raise Exception('Have has no root branch in the git_repos.lst')

  if git_subtrees_root is None:
    git_subtrees_root = wcroot_path + '/.git/svn2git/gitwc'

  root_svn_repopath = root_svn_reporoot + (('/' + root_svn_path_prefix) if root_svn_path_prefix != '' else '')

  git_print_repos_list_header(column_names, column_widths)

  row_values = [root_remote_name, root_git_reporoot, root_parent_git_path_prefix, root_svn_repopath, root_git_local_branch, root_git_remote_branch]
  git_print_repos_list_row(row_values, column_widths)

  # Recursive format:
  #   { <parent_repo_remote_name> : ( <parent_repo_params>, <parent_fetch_state>, { <child_remote_name> : ( <child_repo_params>, <child_fetch_state>, ... ), ... } ) }
  #   , where:
  #
  #   <*_repo_params>:  {
  #     'nest_index'                                      : <integer>,
  #     'parent_tuple_ref'                                : <tuple>,
  #     'children_tuple_ref_list'                         : [<tuple>, ...],
  #     'remote_name'                                     : <string>,
  #     'parent_remote_name'                              : <string>,
  #     'git_reporoot'                                    : <string>,
  #     'parent_git_path_prefix'                          : <string>,
  #     'svn_reporoot'                                    : <string>,
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
  #     'min_tree_time_of_last_unpushed_svn_commit'       : (<timestamp>, <datetime>, <repo_ref>),  # can be a None if have has no not pushed SVN commits
  #
  #     # Has meaning only if a subtree has a read only leaf repository and not pushed commits in it.
  #     # In that case we can make a push only before that commit timestamp, otherwise the read
  #     # only repository must be synchronized some there else to continue with a subtree repositories.
  #     #
  #     'min_ro_tree_time_of_first_unpushed_svn_commit'   : (<timestamp>, <datetime>, <repo_ref>),  # can be a None if have has no not pushed SVN commits
  #                                                                                                 # in a read only leaf repository or does not have read only
  #                                                                                                 # leaf repository in a subtree
  #
  #     'last_pruned_git_svn_commit_dict'                 : {<refspec_token> : <git_hash>, ...}
  #     'last_pushed_git_svn_commit'                      : (<svn_rev>, <git_hash>, <svn_timestamp>, <svn_date_time>),
  #     'unpushed_svn_commit_list'                        : [
  #       (<svn_rev>, <svn_user_name>, <svn_timestamp>, <svn_date_time>), ...
  #     ],
  #
  #     'is_first_time_push'                              : <boolean>
  #   }
  #
  git_svn_repo_tree_dict = {
    root_remote_name : (
      {
        'nest_index'                    : 0,                  # the root
        'parent_tuple_ref'              : None,
        'children_tuple_ref_list'       : [],                 # empty list if have has no children
        'remote_name'                   : root_remote_name,
        'parent_remote_name'            : '.',                # special case: if parent remote name is the '.', then it is the root
        'git_reporoot'                  : root_git_reporoot,
        'parent_git_path_prefix'        : root_parent_git_path_prefix,
        'svn_reporoot'                  : root_svn_reporoot,
        'svn_repo_uuid'                 : '',                 # to avoid complex compare
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

  # repository tree pre-order traversal 
  while True: # read `parent_child_remote_names_to_parse` until empty
    parent_tuple_ref = parent_child_remote_names_to_parse.pop(0)
    parent_repo_params = parent_tuple_ref[0]
    parent_nest_index = parent_repo_params['nest_index']
    parent_remote_name = parent_repo_params['remote_name']
    parent_parent_remote_name = parent_repo_params['parent_remote_name']

    remote_name_list = [parent_remote_name]

    insert_to_front_index = 0

    git_repos_reader.reset()

    for subtree_row in git_repos_reader:
      if subtree_row['scm_token'] == scm_token and subtree_row['branch_type'] != 'root':
        subtree_parent_git_path_prefix = subtree_row['parent_git_path_prefix']

        if subtree_parent_git_path_prefix == '.':
          raise Exception('not root branch type must have not empty git subtree path prefix')

        subtree_parent_remote_name = subtree_row['parent_remote_name']

        if subtree_parent_remote_name == parent_remote_name:
          subtree_remote_name = subtree_row['remote_name']
          subtree_git_reporoot = yaml_expand_global_string(subtree_row['git_reporoot'])
          subtree_svn_reporoot = yaml_expand_global_string(subtree_row['svn_reporoot'])
          subtree_git_local_branch = yaml_expand_global_string(subtree_row['git_local_branch'])
          subtree_git_remote_branch = yaml_expand_global_string(subtree_row['git_remote_branch'])
          subtree_parent_git_path_prefix = yaml_expand_global_string(subtree_parent_git_path_prefix)
          subtree_svn_path_prefix = yaml_expand_global_string(subtree_row['svn_path_prefix'])

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
              'nest_index'                    : parent_nest_index + 1,
              'parent_tuple_ref'              : parent_tuple_ref,
              'children_tuple_ref_list'       : [],                       # empty list if have has no children
              'remote_name'                   : subtree_remote_name,
              'parent_remote_name'            : parent_remote_name,
              'git_reporoot'                  : subtree_git_reporoot,
              'parent_git_path_prefix'        : subtree_parent_git_path_prefix,
              'svn_reporoot'                  : subtree_svn_reporoot,
              'svn_repo_uuid'                 : '',
              'svn_path_prefix'               : subtree_svn_path_prefix,
              'git_local_branch'              : subtree_git_local_branch,
              'git_remote_branch'             : subtree_git_remote_branch,
              'git_wcroot'                    : os.path.abspath(
                  os.path.join(git_subtrees_root, subtree_remote_name + "'" + subtree_parent_git_path_prefix.replace('/', '--'))
                ).replace('\\', '/'),
              'git_ignore_paths_regex'        : ''
            },
            # must be assigned at once, otherwise: `TypeError: 'tuple' object does not support item assignment`
            {},
            {}
          )

          git_svn_repo_tree_tuple_ref_preorder_list.append(child_tuple_ref)

          # push to front instead of popped
          parent_child_remote_names_to_parse.insert(insert_to_front_index, child_tuple_ref)
          insert_to_front_index += 1

    if len(parent_child_remote_names_to_parse) == 0:
      break

  git_print_repos_list_footer(column_widths)

  print('- Indexing children for each parent GIT/SVN repository...')

  git_svn_repo_tree_tuple_ref_index = 0
  git_svn_repo_tree_tuple_ref_preorder_list_size = len(git_svn_repo_tree_tuple_ref_preorder_list)

  for git_svn_repo_tree_tuple_ref in git_svn_repo_tree_tuple_ref_preorder_list:
    parent_repo_params_ref = git_svn_repo_tree_tuple_ref[0]

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

        svn_repo_uuid = ret[1].rstrip()
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

  return (git_svn_repo_tree_dict, git_svn_repo_tree_tuple_ref_preorder_list, svn_repo_root_to_uuid_dict)

def get_git_svn_repos_list_table_params():
  return (
    ['<remote_name>', '<git_reporoot>', '<parent_git_prefix>', '<svn_repopath>', '<git_local_branch>', '<git_remote_branch>'],
    [20, 64, 20, 64, 20, 20]
  )

def get_max_time_depth_in_multiple_svn_commits_fetch_sec():
  # maximal time depth in a multiple svn commits fetch from an svn repository
  return 2678400 # seconds in 1 month (31 days)

def get_root_min_tree_time_of_last_unpushed_svn_commit(git_svn_repo_tree_tuple_ref_preorder_list):
  git_svn_repo_tree_tuple_root_ref = git_svn_repo_tree_tuple_ref_preorder_list[0]
  repo_params_root_ref = git_svn_repo_tree_tuple_root_ref[0]
  if not repo_params_root_ref['parent_tuple_ref'] is None:
    raise Exception('first element in git_svn_repo_tree_tuple_ref_preorder_list is not a tree root')
  fetch_state_root_ref = git_svn_repo_tree_tuple_root_ref[1]
  min_tree_time_of_last_unpushed_svn_commit = fetch_state_root_ref['min_tree_time_of_last_unpushed_svn_commit']
  return min_tree_time_of_last_unpushed_svn_commit

def print_root_min_tree_time_of_last_unpushed_svn_commit(prefix_str, git_svn_repo_tree_tuple_ref_preorder_list, suffix_str = ''):
  min_tree_time_of_last_unpushed_svn_commit = get_root_min_tree_time_of_last_unpushed_svn_commit(git_svn_repo_tree_tuple_ref_preorder_list)
  column_fmt_str = '{:<{}} {:<{}} {:<{}} {:<{}}'
  row_values = [prefix_str, 'root_min_tree_time_of_last_unpushed_svn_commit:', str(min_tree_time_of_last_unpushed_svn_commit[0]) +
    ' {' + min_tree_time_of_last_unpushed_svn_commit[1] + '}', suffix_str]
  column_widths = [3, 52, 40, 20]
  git_print_repos_list_row(row_values, column_widths, column_fmt_str)

def get_subtree_min_ro_tree_time_of_first_unpushed_svn_commit(git_svn_repo_tree_tuple_ref):
  fetch_state_ref = git_svn_repo_tree_tuple_ref[1]
  min_ro_tree_time_of_first_unpushed_svn_commit = fetch_state_ref['min_ro_tree_time_of_first_unpushed_svn_commit']
  return min_ro_tree_time_of_first_unpushed_svn_commit

def get_root_min_ro_tree_time_of_first_unpushed_svn_commit(git_svn_repo_tree_tuple_ref_preorder_list):
  git_svn_repo_tree_tuple_root_ref = git_svn_repo_tree_tuple_ref_preorder_list[0]
  repo_params_root_ref = git_svn_repo_tree_tuple_root_ref[0]
  if not repo_params_root_ref['parent_tuple_ref'] is None:
    raise Exception('first element in git_svn_repo_tree_tuple_ref_preorder_list is not a tree root')
  return get_subtree_min_ro_tree_time_of_first_unpushed_svn_commit(git_svn_repo_tree_tuple_root_ref)

def print_root_min_ro_tree_time_of_first_unpushed_svn_commit(prefix_str, git_svn_repo_tree_tuple_ref_preorder_list, suffix_str = ''):
  min_ro_tree_time_of_first_unpushed_svn_commit = get_root_min_ro_tree_time_of_first_unpushed_svn_commit(git_svn_repo_tree_tuple_ref_preorder_list)
  if not min_ro_tree_time_of_first_unpushed_svn_commit is None:
    column_fmt_str = '{:<{}} {:<{}} {:<{}} {:<{}}'
    row_values = [prefix_str, 'root_min_ro_tree_time_of_first_unpushed_svn_commit:', str(min_ro_tree_time_of_first_unpushed_svn_commit[0]) +
      ' {' + min_ro_tree_time_of_first_unpushed_svn_commit[1] + '}', suffix_str]
    column_widths = [3, 52, 40, 20]
    git_print_repos_list_row(row_values, column_widths, column_fmt_str)

def update_git_svn_repo_fetch_state(git_svn_repo_tree_tuple_ref_preorder_list, max_time_depth_in_multiple_svn_commits_fetch_sec, is_first_time_update, root_only = False):
  print('- Updating GIT-SVN repositories fetch state...')

  first_time_pass = True

  max_time_depth_in_multiple_svn_commits_fetch_sec = get_max_time_depth_in_multiple_svn_commits_fetch_sec()

  while True:
    current_timestamp = datetime.utcnow().timestamp()

    # True if has at least one repository with next timestamp less than current timestamp
    has_not_checked_timeline = False
    unpushed_svn_commit_all_list_len = 0

    for git_svn_repo_tree_tuple_ref in git_svn_repo_tree_tuple_ref_preorder_list:
      repo_params_ref = git_svn_repo_tree_tuple_ref[0]
      fetch_state_ref = git_svn_repo_tree_tuple_ref[1]

      remote_name = repo_params_ref['remote_name']
      git_reporoot = repo_params_ref['git_reporoot']
      svn_reporoot = repo_params_ref['svn_reporoot']
      git_local_branch = repo_params_ref['git_local_branch']
      git_remote_branch = repo_params_ref['git_remote_branch']
      svn_path_prefix = repo_params_ref['svn_path_prefix']
      git_wcroot = repo_params_ref['git_wcroot']

      svn_repopath = svn_reporoot + (('/' + svn_path_prefix) if svn_path_prefix != '' else '')

      with conditional(git_wcroot != '.', local.cwd(git_wcroot)):
        git_remote_refspec_token, git_remote_local_refspec_token = \
          get_git_remote_refspec_token_tuple(remote_name, git_local_branch, git_remote_branch)

        # get last pushed commit hash
        git_last_pushed_commit_hash = get_git_last_pushed_commit_hash(git_reporoot, git_remote_local_refspec_token)

        git_last_svn_rev = 0

        if not git_last_pushed_commit_hash is None:
          # get last git-svn revision w/o fetch because it must be already fetched

          if first_time_pass:
            git_last_svn_rev, git_commit_hash, \
            git_commit_author_timestamp, git_commit_author_date_time, \
            git_commit_timestamp, git_commit_date_time, \
            num_overall_git_commits = \
              get_last_git_svn_rev_by_git_log(remote_name, git_local_branch, git_remote_branch, svn_reporoot, svn_path_prefix)
            if not git_last_svn_rev > 0 and num_overall_git_commits > 0:
              raise Exception('last svn revision is not found in the git log output: path=`{0}`'.format(svn_reporoot + '/' +svn_path_prefix))
          else:
            # read the saved fetch state
            last_pushed_git_svn_commit = fetch_state_ref['last_pushed_git_svn_commit']
            git_last_svn_rev, git_commit_hash, svn_commit_timestamp, svn_commit_date_time = last_pushed_git_svn_commit

          if not git_last_svn_rev >= 0:
            raise Exception('invalid git_last_svn_rev value: `' + str(git_last_svn_rev) + '`')

        if git_last_svn_rev > 0:
          if first_time_pass:
            # NOTE:
            #   1. This might be not required anymore as long the `git svn fetch ...` does use with the `--localtime` parameter,
            #      but left as is for further testing.
            #

            # request svn_commit_timestamp and svn_commit_date_time from svn by git_last_svn_rev
            target_svn_commit_list = get_svn_commit_list(svn_repopath, 1, git_last_svn_rev)

            # update to actual svn commit timestamp and date time
            target_svn_commit = target_svn_commit_list[0]

            target_svn_commit_rev = target_svn_commit[0]
            if target_svn_commit_rev != git_last_svn_rev:
              raise Exception('svn log returned invalid svn revision: requested=' + git_last_svn_rev + ' returned=' + target_svn_commit_rev)

            svn_commit_timestamp = target_svn_commit[2]
            svn_commit_date_time = target_svn_commit[3]
        else:
          # nothing found
          git_commit_hash = None
          git_commit_author_timestamp = None
          git_commit_timestamp = None
          git_commit_author_date_time = None
          git_commit_date_time = None
          svn_commit_timestamp = None
          svn_commit_date_time = None

        # get svn revision list not pushed into respective git repository

        # CAUTION:
        #   1. To make the same output for range of 2 revisions but using a date/time of 2 revisions the both
        #      boundaries must be offsetted by +1 second.
        #   2. If the range parameter in the `svn log ...` command consists only one boundary, then it is
        #      used the same way and must be offsetted by `+1` second to request the revision existed in not
        #      offsetted date/time.
        #

        if git_last_svn_rev > 0:
          git_svn_next_fetch_timestamp = svn_commit_timestamp + max_time_depth_in_multiple_svn_commits_fetch_sec + 1
          git_svn_end_fetch_timestamp = git_svn_next_fetch_timestamp

          # request svn commits limited by a maximal time depth for a multiple svn commits fetch
          to_svn_rev_date_time = datetime.fromtimestamp(git_svn_end_fetch_timestamp, tz = tzlocal.get_localzone()).strftime('%Y-%m-%d %H:%M:%S %z')
          unpushed_svn_commit_list = get_svn_commit_list(svn_repopath, '*', git_last_svn_rev + 1, '{' + to_svn_rev_date_time + '}')
        else:
          # we must test an svn repository on emptiness before call to `svn log ...`
          ret = call_svn(['info', '--show-item', 'last-changed-revision', svn_reporoot])

          svn_last_changed_rev = ret[1].rstrip()
          if len(svn_last_changed_rev) > 0:
            svn_last_changed_rev = int(svn_last_changed_rev)
          else:
            svn_last_changed_rev = 0

          if svn_last_changed_rev > 0:
            # request the first commit to retrieve the commit timestamp to make offset from it
            unpushed_svn_commit_list = get_svn_commit_list(svn_repopath, 1, 1, 'HEAD')

            first_unpushed_svn_commit = unpushed_svn_commit_list[0]

            svn_first_commit_timestamp = first_unpushed_svn_commit[2]

            git_svn_next_fetch_timestamp = svn_first_commit_timestamp + max_time_depth_in_multiple_svn_commits_fetch_sec + 1
            git_svn_end_fetch_timestamp = git_svn_next_fetch_timestamp

            # request svn commits limited by a maximal time depth for a multiple svn commits fetch
            to_svn_rev_date_time = datetime.fromtimestamp(git_svn_end_fetch_timestamp, tz = tzlocal.get_localzone()).strftime('%Y-%m-%d %H:%M:%S %z')
            unpushed_svn_commit_list = get_svn_commit_list(svn_repopath, '*', 1, '{' + to_svn_rev_date_time + '}')
          else:
            unpushed_svn_commit_list = None
            git_svn_next_fetch_timestamp = None

        if not git_svn_next_fetch_timestamp is None:
          if current_timestamp < git_svn_next_fetch_timestamp:
            has_not_checked_timeline = True

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

        # fix up `unpushed_svn_commit_list` if less or equal to the `last_pushed_git_svn_commit`
        if not unpushed_svn_commit_list is None:
          for unpushed_svn_commit in list(unpushed_svn_commit_list):
            if git_last_svn_rev < unpushed_svn_commit[0]:
              break
            unpushed_svn_commit_list.pop(0)

        """
        # If a repository does not have unpushed revisions in a time window, then we must exclude the case
        # where the first unpushed revision is existing but outside a time window.
        if unpushed_svn_commit_list is None or len(unpushed_svn_commit_list) == 0:
          # request first single any revision instead of revisions in a time window
          unpushed_svn_commit_list = get_svn_commit_list(svn_repopath, 1, git_last_svn_rev + 1, 'HEAD')
        """

        unpushed_svn_commit_list_len = len(unpushed_svn_commit_list) if not unpushed_svn_commit_list is None else 0
        if unpushed_svn_commit_list_len > 0:
          last_unpushed_svn_commit = unpushed_svn_commit_list[unpushed_svn_commit_list_len - 1]
          fetch_state_ref['min_tree_time_of_last_unpushed_svn_commit'] = (*last_unpushed_svn_commit[2:4], git_svn_repo_tree_tuple_ref)
          if is_read_only_repo:
            first_unpushed_svn_commit = unpushed_svn_commit_list[0]
            fetch_state_ref['min_ro_tree_time_of_first_unpushed_svn_commit'] = (*first_unpushed_svn_commit[2:4], git_svn_repo_tree_tuple_ref)
          else:
            fetch_state_ref['min_ro_tree_time_of_first_unpushed_svn_commit'] = None
        else:
          # no unpushed svn commits
          fetch_state_ref['min_tree_time_of_last_unpushed_svn_commit'] = None
          fetch_state_ref['min_ro_tree_time_of_first_unpushed_svn_commit'] = None
          unpushed_svn_commit_list = None # to reset to None if empty list

        # accumulate `unpushed_svn_commit_list` size
        unpushed_svn_commit_all_list_len += unpushed_svn_commit_list_len

        # CAUTION:
        #   If has no pushed commits, then the `git_last_svn_rev` is not `None` and equals to `0`, when
        #   all the rest are None.
        #
        fetch_state_ref['last_pushed_git_svn_commit'] = (
          git_last_svn_rev, git_commit_hash,
          int(svn_commit_timestamp) if not svn_commit_timestamp is None else None,
          git_commit_author_date_time
        )

        fetch_state_ref['unpushed_svn_commit_list'] = unpushed_svn_commit_list

        print('---')

        if parent_tuple_ref is None and root_only:
          break

    if unpushed_svn_commit_all_list_len > 0:
      break

    if not has_not_checked_timeline:
      # out of unpushed svn revisions
      break

    # increase svn log size request
    max_time_depth_in_multiple_svn_commits_fetch_sec *= 2
    first_time_pass = False

  if not root_only:
    print('- Updating `min_tree_time_of_last_unpushed_svn_commit`/`min_ro_tree_time_of_first_unpushed_svn_commit`...')

    for git_svn_repo_tree_tuple_ref in reversed(git_svn_repo_tree_tuple_ref_preorder_list): # in reverse
      child_repo_params_ref = git_svn_repo_tree_tuple_ref[0]
      parent_tuple_ref = child_repo_params_ref['parent_tuple_ref']

      if not parent_tuple_ref is None:
        child_fetch_state_ref = git_svn_repo_tree_tuple_ref[1]

        parent_fetch_state_ref = parent_tuple_ref[1]

        child_min_tree_time_of_last_unpushed_svn_commit = child_fetch_state_ref['min_tree_time_of_last_unpushed_svn_commit']
        if not child_min_tree_time_of_last_unpushed_svn_commit is None:
          parent_min_tree_time_of_last_unpushed_svn_commit = parent_fetch_state_ref['min_tree_time_of_last_unpushed_svn_commit']
          if not parent_min_tree_time_of_last_unpushed_svn_commit is None:
            if child_min_tree_time_of_last_unpushed_svn_commit[0] < parent_min_tree_time_of_last_unpushed_svn_commit[0]:
              parent_fetch_state_ref['min_tree_time_of_last_unpushed_svn_commit'] = child_min_tree_time_of_last_unpushed_svn_commit
          else:
            parent_fetch_state_ref['min_tree_time_of_last_unpushed_svn_commit'] = child_min_tree_time_of_last_unpushed_svn_commit

        child_min_ro_tree_time_of_first_unpushed_svn_commit = child_fetch_state_ref['min_ro_tree_time_of_first_unpushed_svn_commit']
        if not child_min_ro_tree_time_of_first_unpushed_svn_commit is None:
          parent_min_ro_tree_time_of_first_unpushed_svn_commit = parent_fetch_state_ref['min_ro_tree_time_of_first_unpushed_svn_commit']
          if not parent_min_ro_tree_time_of_first_unpushed_svn_commit is None:
            if child_min_ro_tree_time_of_first_unpushed_svn_commit[0] < parent_min_ro_tree_time_of_first_unpushed_svn_commit [0]:
              parent_fetch_state_ref['min_ro_tree_time_of_first_unpushed_svn_commit'] = child_min_ro_tree_time_of_first_unpushed_svn_commit
          else:
            parent_fetch_state_ref['min_ro_tree_time_of_first_unpushed_svn_commit'] = child_min_ro_tree_time_of_first_unpushed_svn_commit

  if unpushed_svn_commit_all_list_len == 0:
    print('  No unpushed SVN revisions to update.')
    return False

  print('- Updated GIT-SVN repositories:')

  column_names = ['<remote_name>', '<last_pushed_git_svn_commit>', '<unpushed_svn_commit_list>', '<min_ro_tree_time_of_first_unpushed_svn_commit>', '<fetch_rev>', '<RO>']
  column_widths = [20, 48, 36, 47, 11, 4]

  git_print_repos_list_header(column_names, column_widths)

  for git_svn_repo_tree_tuple_ref in git_svn_repo_tree_tuple_ref_preorder_list:
    repo_params_ref = git_svn_repo_tree_tuple_ref[0]
    fetch_state_ref = git_svn_repo_tree_tuple_ref[1]

    repo_nest_index = repo_params_ref['nest_index']
    remote_name = repo_params_ref['remote_name']

    is_read_only_repo = fetch_state_ref['is_read_only_repo']
    min_ro_tree_time_of_first_unpushed_svn_commit = fetch_state_ref['min_ro_tree_time_of_first_unpushed_svn_commit']
    unpushed_svn_commit_list = fetch_state_ref['unpushed_svn_commit_list']
    last_pushed_git_svn_commit = fetch_state_ref['last_pushed_git_svn_commit']
    last_pushed_git_svn_commit_rev = last_pushed_git_svn_commit[0]

    remote_name_prefix_str = '| ' * repo_nest_index

    # can be less or equal to the pushed one, we have to intercept that
    is_first_unpushed_svn_commit_invalid = False

    unpushed_svn_commit_list_str = ''
    if not unpushed_svn_commit_list is None:
      unpushed_svn_commit_list_len = len(unpushed_svn_commit_list)
      if unpushed_svn_commit_list_len > 0:
        # validate first unpushed svn revision
        if last_pushed_git_svn_commit_rev >= unpushed_svn_commit_list[0][0]:
          is_first_unpushed_svn_commit_invalid = True

        if unpushed_svn_commit_list_len > 4:
          unpushed_svn_commit_list_str = '[' + \
            str(unpushed_svn_commit_list[0][0]) + ' ' + str(unpushed_svn_commit_list[1][0]) + ' ... ' + \
            str(unpushed_svn_commit_list[-2][0]) + ' ' + str(unpushed_svn_commit_list[-1][0]) + ']'
        else:
          text = ''
          for unpushed_svn_commit in unpushed_svn_commit_list:
            if len(text) > 0:
              text += ' '
            text += str(unpushed_svn_commit[0])
          unpushed_svn_commit_list_str = '[' + text + ']'

    last_pushed_git_svn_commit_rev_str = 'r' + str(last_pushed_git_svn_commit_rev)
    last_pushed_git_svn_commit_rev_str_len = len(last_pushed_git_svn_commit_rev_str)

    last_pushed_git_svn_commit_rev_str_max_len = 9

    row_values = [
      remote_name_prefix_str + remote_name,
      last_pushed_git_svn_commit_rev_str + (' ' * max(1, last_pushed_git_svn_commit_rev_str_max_len + 1 - last_pushed_git_svn_commit_rev_str_len)) + \
        (str(last_pushed_git_svn_commit[2]) + ' {' + last_pushed_git_svn_commit[3] + '}') if last_pushed_git_svn_commit_rev > 0 else '',
      unpushed_svn_commit_list_str,
      (str(min_ro_tree_time_of_first_unpushed_svn_commit[0]) + ' {' + min_ro_tree_time_of_first_unpushed_svn_commit[1] + '}') \
        if not min_ro_tree_time_of_first_unpushed_svn_commit is None else '',
      'r' + str(last_pushed_git_svn_commit_rev),
      'Y' if is_read_only_repo else ''
    ]
    git_print_repos_list_row(row_values, column_widths)

  git_print_repos_list_footer(column_widths)

  print_root_min_tree_time_of_last_unpushed_svn_commit('  * - ', git_svn_repo_tree_tuple_ref_preorder_list)

  if is_first_unpushed_svn_commit_invalid:
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

  print(' ->> wcroot: `{0}`'.format(wcroot_path))

  if not os.path.exists(wcroot_path):
    os.mkdir(wcroot_path)

  max_time_depth_in_multiple_svn_commits_fetch_sec = get_max_time_depth_in_multiple_svn_commits_fetch_sec()

  with local.cwd(wcroot_path), GitReposListReader(configure_dir + '/git_repos.lst') as git_repos_reader, ServiceProcCache() as svc_proc_cache:
    executed_procs = cache_init_service_proc(svc_proc_cache)

    with tkl.OnExit(lambda: cache_close_running_procs(executed_procs, svc_proc_cache)):
      column_names, column_widths = get_git_svn_repos_list_table_params()

      if git_subtrees_root is None:
        git_subtrees_root = wcroot_path + '/.git/svn2git/gitwc'

      git_svn_repo_tree_dict, git_svn_repo_tree_tuple_ref_preorder_list, svn_repo_root_to_uuid_dict = \
        read_git_svn_repo_list(git_repos_reader, scm_token, wcroot_path, git_subtrees_root, column_names, column_widths,
          update_svn_repo_uuid = update_svn_repo_uuid)

      print('- GIT fetching...')

      for git_svn_repo_tree_tuple_ref in git_svn_repo_tree_tuple_ref_preorder_list:
        repo_params_ref = git_svn_repo_tree_tuple_ref[0]

        parent_tuple_ref = repo_params_ref['parent_tuple_ref']

        remote_name = repo_params_ref['remote_name']
        parent_remote_name = repo_params_ref['parent_remote_name']

        git_reporoot = repo_params_ref['git_reporoot']
        svn_reporoot = repo_params_ref['svn_reporoot']

        parent_git_path_prefix = repo_params_ref['parent_git_path_prefix']
        svn_path_prefix = repo_params_ref['svn_path_prefix']

        git_local_branch = repo_params_ref['git_local_branch']
        git_remote_branch = repo_params_ref['git_remote_branch']

        if not parent_tuple_ref is None:
          subtree_git_wcroot = os.path.abspath(os.path.join(git_subtrees_root, remote_name + "'" + parent_git_path_prefix.replace('/', '--'))).replace('\\', '/')

          print(' ->> cwd: `{0}`...'.format(subtree_git_wcroot))
        else:
          print(' ->> cwd: `{0}`...'.format(wcroot_path))

        with conditional(not parent_tuple_ref is None, local.cwd(subtree_git_wcroot) if not parent_tuple_ref is None else None):
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

      update_git_svn_repo_fetch_state(git_svn_repo_tree_tuple_ref_preorder_list, max_time_depth_in_multiple_svn_commits_fetch_sec, root_only = root_only, is_first_time_update = True)

      print('- GIT-SVN fetching...')

      for git_svn_repo_tree_tuple_ref in git_svn_repo_tree_tuple_ref_preorder_list:
        repo_params_ref = git_svn_repo_tree_tuple_ref[0]
        fetch_state_ref = git_svn_repo_tree_tuple_ref[1]

        parent_tuple_ref = repo_params_ref['parent_tuple_ref']

        remote_name = repo_params_ref['remote_name']

        git_reporoot = repo_params_ref['git_reporoot']
        svn_reporoot = repo_params_ref['svn_reporoot']

        parent_git_path_prefix = repo_params_ref['parent_git_path_prefix']
        svn_path_prefix = repo_params_ref['svn_path_prefix']

        git_local_branch = repo_params_ref['git_local_branch']
        git_remote_branch = repo_params_ref['git_remote_branch']

        git_svn_fetch_ignore_paths_regex = repo_params_ref['git_ignore_paths_regex']

        if not parent_tuple_ref is None:
          subtree_git_wcroot = os.path.abspath(os.path.join(git_subtrees_root, remote_name + "'" + parent_git_path_prefix.replace('/', '--'))).replace('\\', '/')

          print(' ->> cwd: `{0}`...'.format(subtree_git_wcroot))
        else:
          print(' ->> cwd: `{0}`...'.format(wcroot_path))

        with conditional(not parent_tuple_ref is None, local.cwd(subtree_git_wcroot) if not parent_tuple_ref is None else None):
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

          """
          # CAUTION:
          #   1. We can not rollback the svn remote branch to a particular revision through the `git svn reset -r <rev>` because
          #      the branch can be w/o a common ancestor which is a requirement to success accomplish.
          #      Instead of drop revisions in a branch do remove entire branch and the index, so the next fetch command would
          #      retake the target revision again.
          #
          git_svn_trunk_remote_refspec_shorted_token = get_git_svn_trunk_remote_refspec_token(remote_name, shorted = True)
          git_svn_trunk_remote_refspec_token = get_git_svn_trunk_remote_refspec_token(remote_name)

          git_remove_svn_branch(git_svn_trunk_remote_refspec_shorted_token, git_svn_trunk_remote_refspec_token)
          """

          # direct use of the config section name `svn`
          last_pushed_git_svn_commit = fetch_state_ref['last_pushed_git_svn_commit']
          last_pushed_git_svn_commit_rev = last_pushed_git_svn_commit[0]

          git_local_refspec_token = get_git_local_refspec_token(git_local_branch, git_remote_branch)
          git_remote_refspec_token, git_remote_local_refspec_token = \
            get_git_remote_refspec_token_tuple(remote_name, git_local_branch, git_remote_branch)

          git_svn_fetch(last_pushed_git_svn_commit_rev, last_pushed_git_svn_commit_rev, git_svn_fetch_cmdline_list,
            remote_name, git_local_branch,
            git_local_refspec_token, git_remote_refspec_token, last_pruned_git_svn_commit_dict,
            prune_empty_git_svn_commits)

          # revert again if last fetch has broke the HEAD

          # get last pushed commit hash
          git_last_pushed_commit_hash = get_git_last_pushed_commit_hash(git_reporoot, git_remote_local_refspec_token)

          git_reset_if_head_is_not_last_pushed(git_last_pushed_commit_hash, git_local_refspec_token, git_remote_refspec_token,
            reset_hard = reset_hard)

          """
          if not parent_tuple_ref is None:
            with open('.git/HEAD', 'wt') as head_file:
              head_file.write('ref: ' + git_local_refspec_token)
              head_file.close()
          """

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

  print(' ->> wcroot: `{0}`'.format(wcroot_path))

  if not os.path.exists(wcroot_path):
    os.mkdir(wcroot_path)

  with local.cwd(wcroot_path), GitReposListReader(configure_dir + '/git_repos.lst') as git_repos_reader, ServiceProcCache() as svc_proc_cache:
    executed_procs = cache_init_service_proc(svc_proc_cache)

    with tkl.OnExit(lambda: cache_close_running_procs(executed_procs, svc_proc_cache)):
      column_names, column_widths = get_git_svn_repos_list_table_params()

      if git_subtrees_root is None:
        git_subtrees_root = wcroot_path + '/.git/svn2git/gitwc'

      git_svn_repo_tree_dict, git_svn_repo_tree_tuple_ref_preorder_list, svn_repo_root_to_uuid_dict = \
        read_git_svn_repo_list(git_repos_reader, scm_token, wcroot_path, git_subtrees_root, column_names, column_widths,
          update_svn_repo_uuid = update_svn_repo_uuid)

      print('- GIT switching...')

      for git_svn_repo_tree_tuple_ref in git_svn_repo_tree_tuple_ref_preorder_list:
        repo_params_ref = git_svn_repo_tree_tuple_ref[0]

        parent_tuple_ref = repo_params_ref['parent_tuple_ref']

        remote_name = repo_params_ref['remote_name']

        git_reporoot = repo_params_ref['git_reporoot']

        parent_git_path_prefix = repo_params_ref['parent_git_path_prefix']

        git_local_branch = repo_params_ref['git_local_branch']
        git_remote_branch = repo_params_ref['git_remote_branch']

        if not parent_tuple_ref is None:
          subtree_git_wcroot = os.path.abspath(os.path.join(git_subtrees_root, remote_name + "'" + parent_git_path_prefix.replace('/', '--'))).replace('\\', '/')

          print(' ->> cwd: `{0}`...'.format(subtree_git_wcroot))
        else:
          print(' ->> cwd: `{0}`...'.format(wcroot_path))

        with conditional(not parent_tuple_ref is None, local.cwd(subtree_git_wcroot) if not parent_tuple_ref is None else None):
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

        remote_name = repo_params_ref['remote_name']

        git_reporoot = repo_params_ref['git_reporoot']

        parent_git_path_prefix = repo_params_ref['parent_git_path_prefix']

        git_local_branch = repo_params_ref['git_local_branch']
        git_remote_branch = repo_params_ref['git_remote_branch']

        if not parent_tuple_ref is None:
          subtree_git_wcroot = os.path.abspath(os.path.join(git_subtrees_root, remote_name + "'" + parent_git_path_prefix.replace('/', '--'))).replace('\\', '/')

          print(' ->> cwd: `{0}`...'.format(subtree_git_wcroot))
        else:
          print(' ->> cwd: `{0}`...'.format(wcroot_path))

        with conditional(not parent_tuple_ref is None, local.cwd(subtree_git_wcroot) if not parent_tuple_ref is None else None):
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

          """
          if not parent_tuple_ref is None:
            with open('.git/HEAD', 'wt') as head_file:
              head_file.write('ref: ' + git_local_refspec_token)
              head_file.close()
          """

          print('---')

          if parent_tuple_ref is None and root_only:
            break

      print('- GIT-SVN resetting...')

      for git_svn_repo_tree_tuple_ref in git_svn_repo_tree_tuple_ref_preorder_list:
        repo_params_ref = git_svn_repo_tree_tuple_ref[0]

        parent_tuple_ref = repo_params_ref['parent_tuple_ref']

        remote_name = repo_params_ref['remote_name']

        git_local_branch = repo_params_ref['git_local_branch']

        parent_git_path_prefix = repo_params_ref['parent_git_path_prefix']

        if not parent_tuple_ref is None:
          subtree_git_wcroot = os.path.abspath(os.path.join(git_subtrees_root, remote_name + "'" + parent_git_path_prefix.replace('/', '--'))).replace('\\', '/')

          print(' ->> cwd: `{0}`...'.format(subtree_git_wcroot))
        else:
          print(' ->> cwd: `{0}`...'.format(wcroot_path))

        with conditional(not parent_tuple_ref is None, local.cwd(subtree_git_wcroot) if not parent_tuple_ref is None else None):
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

  print(' ->> wcroot: `{0}`'.format(wcroot_path))

  if not os.path.exists(wcroot_path):
    os.mkdir(wcroot_path)

  max_time_depth_in_multiple_svn_commits_fetch_sec = get_max_time_depth_in_multiple_svn_commits_fetch_sec()

  with local.cwd(wcroot_path), GitReposListReader(configure_dir + '/git_repos.lst') as git_repos_reader, ServiceProcCache() as svc_proc_cache:
    executed_procs = cache_init_service_proc(svc_proc_cache)

    with tkl.OnExit(lambda: cache_close_running_procs(executed_procs, svc_proc_cache)):
      column_names, column_widths = get_git_svn_repos_list_table_params()

      if git_subtrees_root is None:
        git_subtrees_root = wcroot_path + '/.git/svn2git/gitwc'

      git_svn_repo_tree_dict, git_svn_repo_tree_tuple_ref_preorder_list, svn_repo_root_to_uuid_dict = \
        read_git_svn_repo_list(git_repos_reader, scm_token, wcroot_path, git_subtrees_root, column_names, column_widths,
          update_svn_repo_uuid = update_svn_repo_uuid)

      print('- GIT switching...')

      for git_svn_repo_tree_tuple_ref in git_svn_repo_tree_tuple_ref_preorder_list:
        repo_params_ref = git_svn_repo_tree_tuple_ref[0]

        parent_tuple_ref = repo_params_ref['parent_tuple_ref']

        remote_name = repo_params_ref['remote_name']

        git_reporoot = repo_params_ref['git_reporoot']

        parent_git_path_prefix = repo_params_ref['parent_git_path_prefix']

        git_local_branch = repo_params_ref['git_local_branch']
        git_remote_branch = repo_params_ref['git_remote_branch']

        if not parent_tuple_ref is None:
          subtree_git_wcroot = os.path.abspath(os.path.join(git_subtrees_root, remote_name + "'" + parent_git_path_prefix.replace('/', '--'))).replace('\\', '/')

          print(' ->> cwd: `{0}`...'.format(subtree_git_wcroot))
        else:
          print(' ->> cwd: `{0}`...'.format(wcroot_path))

        with conditional(not parent_tuple_ref is None, local.cwd(subtree_git_wcroot) if not parent_tuple_ref is None else None):
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

        remote_name = repo_params_ref['remote_name']
        parent_remote_name = repo_params_ref['parent_remote_name']

        git_reporoot = repo_params_ref['git_reporoot']

        parent_git_path_prefix = repo_params_ref['parent_git_path_prefix']

        git_local_branch = repo_params_ref['git_local_branch']
        git_remote_branch = repo_params_ref['git_remote_branch']

        if not parent_tuple_ref is None:
          subtree_git_wcroot = os.path.abspath(os.path.join(git_subtrees_root, remote_name + "'" + parent_git_path_prefix.replace('/', '--'))).replace('\\', '/')

          print(' ->> cwd: `{0}`...'.format(subtree_git_wcroot))
        else:
          print(' ->> cwd: `{0}`...'.format(wcroot_path))

        with conditional(not parent_tuple_ref is None, local.cwd(subtree_git_wcroot) if not parent_tuple_ref is None else None):
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

      update_git_svn_repo_fetch_state(git_svn_repo_tree_tuple_ref_preorder_list, max_time_depth_in_multiple_svn_commits_fetch_sec, root_only = root_only, is_first_time_update = True)

      print('- GIT-SVN fetching...')

      for git_svn_repo_tree_tuple_ref in git_svn_repo_tree_tuple_ref_preorder_list:
        repo_params_ref = git_svn_repo_tree_tuple_ref[0]
        fetch_state_ref = git_svn_repo_tree_tuple_ref[1]

        parent_tuple_ref = repo_params_ref['parent_tuple_ref']

        remote_name = repo_params_ref['remote_name']

        git_reporoot = repo_params_ref['git_reporoot']
        svn_reporoot = repo_params_ref['svn_reporoot']

        parent_git_path_prefix = repo_params_ref['parent_git_path_prefix']

        git_local_branch = repo_params_ref['git_local_branch']
        git_remote_branch = repo_params_ref['git_remote_branch']

        git_svn_fetch_ignore_paths_regex = repo_params_ref['git_ignore_paths_regex']

        if not parent_tuple_ref is None:
          subtree_git_wcroot = os.path.abspath(os.path.join(git_subtrees_root, remote_name + "'" + parent_git_path_prefix.replace('/', '--'))).replace('\\', '/')

          print(' ->> cwd: `{0}`...'.format(subtree_git_wcroot))
        else:
          print(' ->> cwd: `{0}`...'.format(wcroot_path))

        with conditional(not parent_tuple_ref is None, local.cwd(subtree_git_wcroot) if not parent_tuple_ref is None else None):
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

          """
          # CAUTION:
          #   1. We can not rollback the svn remote branch to a particular revision through the `git svn reset -r <rev>` because
          #      the branch can be w/o a common ancestor which is a requirement to success accomplish.
          #      Instead of drop revisions in a branch do remove entire branch and the index, so the next fetch command would
          #      retake the target revision again.
          #
          git_svn_trunk_remote_refspec_shorted_token = get_git_svn_trunk_remote_refspec_token(remote_name, shorted = True)
          git_svn_trunk_remote_refspec_token = get_git_svn_trunk_remote_refspec_token(remote_name)

          git_remove_svn_branch(git_svn_trunk_remote_refspec_shorted_token, git_svn_trunk_remote_refspec_token)
          """

          # direct use of the config section name `svn`
          last_pushed_git_svn_commit = fetch_state_ref['last_pushed_git_svn_commit']
          last_pushed_git_svn_commit_rev = last_pushed_git_svn_commit[0]

          git_local_refspec_token = get_git_local_refspec_token(git_local_branch, git_remote_branch)
          git_remote_refspec_token, git_remote_local_refspec_token = \
            get_git_remote_refspec_token_tuple(remote_name, git_local_branch, git_remote_branch)

          git_svn_fetch(last_pushed_git_svn_commit_rev, last_pushed_git_svn_commit_rev, git_svn_fetch_cmdline_list,
            remote_name, git_local_branch,
            git_local_refspec_token, git_remote_refspec_token, last_pruned_git_svn_commit_dict,
            prune_empty_git_svn_commits)

          # revert again if last fetch has broke the HEAD

          # get last pushed commit hash
          git_last_pushed_commit_hash = get_git_last_pushed_commit_hash(git_reporoot, git_remote_local_refspec_token)

          git_reset_if_head_is_not_last_pushed(git_last_pushed_commit_hash, git_local_refspec_token, git_remote_refspec_token,
            reset_hard = reset_hard)

          """
          if not parent_tuple_ref is None:
            with open('.git/HEAD', 'wt') as head_file:
              head_file.write('ref: ' + git_local_refspec_token)
              head_file.close()
          """

          print('---')

          if parent_tuple_ref is None and root_only:
            break

      print('- GIT checkouting...')

      for git_svn_repo_tree_tuple_ref in git_svn_repo_tree_tuple_ref_preorder_list:
        repo_params_ref = git_svn_repo_tree_tuple_ref[0]

        parent_tuple_ref = repo_params_ref['parent_tuple_ref']

        remote_name = repo_params_ref['remote_name']

        parent_git_path_prefix = repo_params_ref['parent_git_path_prefix']

        git_local_branch = repo_params_ref['git_local_branch']
        git_remote_branch = repo_params_ref['git_remote_branch']

        if not parent_tuple_ref is None:
          subtree_git_wcroot = os.path.abspath(os.path.join(git_subtrees_root, remote_name + "'" + parent_git_path_prefix.replace('/', '--'))).replace('\\', '/')

          print(' ->> cwd: `{0}`...'.format(subtree_git_wcroot))
        else:
          print(' ->> cwd: `{0}`...'.format(wcroot_path))

        with conditional(not parent_tuple_ref is None, local.cwd(subtree_git_wcroot) if not parent_tuple_ref is None else None):
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

def collect_unpushed_svn_revisions_ordered_by_timestamp(git_svn_repo_tree_tuple_ref_preorder_list):
  print('- Collecting unpushed svn commits:')

  unpushed_svn_commit_by_timestamp_dict = {}

  for git_svn_repo_tree_tuple_ref in reversed(git_svn_repo_tree_tuple_ref_preorder_list): # in reverse
    fetch_state_ref = git_svn_repo_tree_tuple_ref[1]

    min_tree_time_of_last_unpushed_svn_commit = fetch_state_ref['min_tree_time_of_last_unpushed_svn_commit']
    min_ro_tree_time_of_first_unpushed_svn_commit = fetch_state_ref['min_ro_tree_time_of_first_unpushed_svn_commit']

    unpushed_svn_commit_list = fetch_state_ref['unpushed_svn_commit_list']
    for unpushed_svn_commit in unpushed_svn_commit_list:
      unpushed_svn_commit_timestamp = unpushed_svn_commit[2]
      if not min_tree_time_of_last_unpushed_svn_commit is None and \
         unpushed_svn_commit_timestamp > min_tree_time_of_last_unpushed_svn_commit[0]:
        break

      unpushed_svn_commit_by_timestamp = unpushed_svn_commit_by_timestamp_dict.get(unpushed_svn_commit_timestamp)
      if not unpushed_svn_commit_by_timestamp is None:
        # append to the end, because repos already being traversed in reverse order to the tree preorder traversal
        unpushed_svn_commit_by_timestamp.append((unpushed_svn_commit[0], unpushed_svn_commit[3], git_svn_repo_tree_tuple_ref))
      else:
        unpushed_svn_commit_by_timestamp_dict[unpushed_svn_commit_timestamp] = \
          [(unpushed_svn_commit[0], unpushed_svn_commit[3], git_svn_repo_tree_tuple_ref)]

      if not min_ro_tree_time_of_first_unpushed_svn_commit is None and \
         unpushed_svn_commit_timestamp >= min_ro_tree_time_of_first_unpushed_svn_commit[0]:
        break

  min_tree_time_of_last_unpushed_svn_commit = get_root_min_tree_time_of_last_unpushed_svn_commit(git_svn_repo_tree_tuple_ref_preorder_list)
  min_tree_time_of_last_unpushed_svn_commit_timestamp = min_tree_time_of_last_unpushed_svn_commit[0]

  column_fmt_str = '{:<{}} {:<{}} {:<{}} {:<{}}'
  column_names = ['<svn_timestamp_datetime>', '<rev>', '<remote_name>', '<svn_repopath>']
  column_widths = [43, 9, 20, 64]

  git_print_repos_list_header(column_names, column_widths, column_fmt_str)

  for unpushed_svn_commit_timestamp, unpushed_svn_commit_list in sorted(unpushed_svn_commit_by_timestamp_dict.items()):
    for unpushed_svn_commit_tuple in unpushed_svn_commit_list:
      unpushed_svn_commit_rev = unpushed_svn_commit_tuple[0]
      unpushed_svn_commit_datetime = unpushed_svn_commit_tuple[1]
      unpushed_svn_commit_git_svn_repo_tree_tuple_ref = unpushed_svn_commit_tuple[2]

      repo_params_ref = unpushed_svn_commit_git_svn_repo_tree_tuple_ref[0]
      fetch_state_ref = unpushed_svn_commit_git_svn_repo_tree_tuple_ref[1]

      nest_index = repo_params_ref['nest_index']
      remote_name = repo_params_ref['remote_name']
      svn_reporoot = repo_params_ref['svn_reporoot']
      svn_path_prefix = repo_params_ref['svn_path_prefix']

      svn_repopath = svn_reporoot + (('/' + svn_path_prefix) if svn_path_prefix != '' else '')

      is_read_only_repo = fetch_state_ref['is_read_only_repo']

      if not is_read_only_repo:
        row_values = [('* ' if unpushed_svn_commit_timestamp == min_tree_time_of_last_unpushed_svn_commit_timestamp else '  ') + \
          str(unpushed_svn_commit_timestamp) + ' {' + unpushed_svn_commit_tuple[1] + '}',
          'r' + str(unpushed_svn_commit_tuple[0]), ('| ' * nest_index) + remote_name, svn_repopath]
      else:
        row_values = ['o ' + \
          str(unpushed_svn_commit_timestamp) + ' {' + unpushed_svn_commit_tuple[1] + '}',
          'r' + str(unpushed_svn_commit_tuple[0]), ('| ' * nest_index) + remote_name, svn_repopath]
      git_print_repos_list_row(row_values, column_widths, column_fmt_str)

  git_print_repos_list_footer(column_widths)

  print_root_min_tree_time_of_last_unpushed_svn_commit('  * -', git_svn_repo_tree_tuple_ref_preorder_list)
  print_root_min_ro_tree_time_of_first_unpushed_svn_commit('  o -', git_svn_repo_tree_tuple_ref_preorder_list)

  return unpushed_svn_commit_by_timestamp_dict

def collect_last_pushed_git_svn_commits_by_max_timestamp(git_svn_repo_tree_tuple_ref_preorder_list):
  last_pushed_git_svn_commits_by_last_timestamp_list = []
  last_pushed_git_svn_commit_max_timestamp = 0

  for git_svn_repo_tree_tuple_ref in git_svn_repo_tree_tuple_ref_preorder_list:
    fetch_state_ref = git_svn_repo_tree_tuple_ref[1]

    last_pushed_git_svn_commit = fetch_state_ref['last_pushed_git_svn_commit']
    last_pushed_git_svn_commit_rev = last_pushed_git_svn_commit[0]
    if last_pushed_git_svn_commit_rev > 0:
      last_pushed_git_svn_commit_timestamp = last_pushed_git_svn_commit[2]
      if last_pushed_git_svn_commit_max_timestamp < last_pushed_git_svn_commit_timestamp:
        last_pushed_git_svn_commit_max_timestamp = last_pushed_git_svn_commit_timestamp
        # reset the list
        last_pushed_git_svn_commits_by_last_timestamp_list = [git_svn_repo_tree_tuple_ref]
      elif last_pushed_git_svn_commit_max_timestamp == last_pushed_git_svn_commit_timestamp:
        last_pushed_git_svn_commits_by_last_timestamp_list.append(git_svn_repo_tree_tuple_ref)

  return (last_pushed_git_svn_commits_by_last_timestamp_list, last_pushed_git_svn_commit_max_timestamp)

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

# CAUTION:
#   * The function always does process the root repository together along with the subtree repositories, because
#     it is a part of a whole 1-way synchronization process between the SVN and the GIT.
#     If you want to reduce the depth or change the configuration of subtrees, you have to edit the respective
#     `git_repos.lst` file.
#     If you want to process subtree repositories by a custom (not builtin) path,
#     then do use the `git_subtrees_root` argument as a root path to the subtree directories.
#
def git_push_from_svn(configure_dir, scm_token, git_subtrees_root = None, reset_hard = False,
                      prune_empty_git_svn_commits = True, retain_commmit_git_svn_parents = False, verbosity = 0):
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

  print(' ->> wcroot: `{0}`'.format(wcroot_path))

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

  with local.cwd(wcroot_path), GitReposListReader(configure_dir + '/git_repos.lst') as git_repos_reader, ServiceProcCache() as svc_proc_cache:
    executed_procs = cache_init_service_proc(svc_proc_cache)

    with tkl.OnExit(lambda: cache_close_running_procs(executed_procs, svc_proc_cache)):
      column_names, column_widths = get_git_svn_repos_list_table_params()

      if git_subtrees_root is None:
        git_subtrees_root = wcroot_path + '/.git/svn2git/gitwc'

      git_svn_repo_tree_dict, git_svn_repo_tree_tuple_ref_preorder_list, svn_repo_root_to_uuid_dict = \
        read_git_svn_repo_list(git_repos_reader, scm_token, wcroot_path, git_subtrees_root, column_names, column_widths)

      print('- GIT switching...')

      for git_svn_repo_tree_tuple_ref in git_svn_repo_tree_tuple_ref_preorder_list:
        repo_params_ref = git_svn_repo_tree_tuple_ref[0]

        parent_tuple_ref = repo_params_ref['parent_tuple_ref']

        remote_name = repo_params_ref['remote_name']

        parent_git_path_prefix = repo_params_ref['parent_git_path_prefix']

        git_local_branch = repo_params_ref['git_local_branch']
        git_remote_branch = repo_params_ref['git_remote_branch']

        if not parent_tuple_ref is None:
          subtree_git_wcroot = os.path.abspath(os.path.join(git_subtrees_root, remote_name + "'" + parent_git_path_prefix.replace('/', '--'))).replace('\\', '/')

          print(' ->> cwd: `{0}`...'.format(subtree_git_wcroot))
        else:
          print(' ->> cwd: `{0}`...'.format(wcroot_path))

        with conditional(not parent_tuple_ref is None, local.cwd(subtree_git_wcroot) if not parent_tuple_ref is None else None):
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

        remote_name = repo_params_ref['remote_name']
        parent_remote_name = repo_params_ref['parent_remote_name']

        git_reporoot = repo_params_ref['git_reporoot']
        svn_reporoot = repo_params_ref['svn_reporoot']

        parent_git_path_prefix = repo_params_ref['parent_git_path_prefix']
        svn_path_prefix = repo_params_ref['svn_path_prefix']

        git_local_branch = repo_params_ref['git_local_branch']
        git_remote_branch = repo_params_ref['git_remote_branch']

        if not parent_tuple_ref is None:
          subtree_git_wcroot = os.path.abspath(os.path.join(git_subtrees_root, remote_name + "'" + parent_git_path_prefix.replace('/', '--'))).replace('\\', '/')

          print(' ->> cwd: `{0}`...'.format(subtree_git_wcroot))
        else:
          print(' ->> cwd: `{0}`...'.format(wcroot_path))

        with conditional(not parent_tuple_ref is None, local.cwd(subtree_git_wcroot) if not parent_tuple_ref is None else None):
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

      # 1. + 2.
      #

      has_unpushed_svn_revisions_to_update = \
        update_git_svn_repo_fetch_state(git_svn_repo_tree_tuple_ref_preorder_list, max_time_depth_in_multiple_svn_commits_fetch_sec, is_first_time_update = True)

      # we still have to checkout before quit
      if has_unpushed_svn_revisions_to_update:
        print('- GIT-SVN fetching...')

        for git_svn_repo_tree_tuple_ref in git_svn_repo_tree_tuple_ref_preorder_list:
          repo_params_ref = git_svn_repo_tree_tuple_ref[0]
          fetch_state_ref = git_svn_repo_tree_tuple_ref[1]

          parent_tuple_ref = repo_params_ref['parent_tuple_ref']

          remote_name = repo_params_ref['remote_name']

          git_reporoot = repo_params_ref['git_reporoot']
          svn_reporoot = repo_params_ref['svn_reporoot']

          parent_git_path_prefix = repo_params_ref['parent_git_path_prefix']

          git_local_branch = repo_params_ref['git_local_branch']
          git_remote_branch = repo_params_ref['git_remote_branch']

          git_svn_fetch_ignore_paths_regex = repo_params_ref['git_ignore_paths_regex']

          if not parent_tuple_ref is None:
            subtree_git_wcroot = os.path.abspath(os.path.join(git_subtrees_root, remote_name + "'" + parent_git_path_prefix.replace('/', '--'))).replace('\\', '/')

            print(' ->> cwd: `{0}`...'.format(subtree_git_wcroot))
          else:
            print(' ->> cwd: `{0}`...'.format(wcroot_path))

          with conditional(not parent_tuple_ref is None, local.cwd(subtree_git_wcroot) if not parent_tuple_ref is None else None):
            last_pruned_git_svn_commit_dict = fetch_state_ref['last_pruned_git_svn_commit_dict']

            git_svn_fetch_cmdline_list = []

            if len(git_svn_fetch_ignore_paths_regex) > 0:
              git_svn_fetch_cmdline_list.append('--ignore-paths=' + git_svn_fetch_ignore_paths_regex)

            # git-svn (re)fetch next svn revision

            """
            # CAUTION:
            #   1. We can not rollback the svn remote branch to a particular revision through the `git svn reset -r <rev>` because
            #      the branch can be w/o a common ancestor which is a requirement to success accomplish.
            #      Instead of drop revisions in a branch do remove entire branch and the index, so the next fetch command would
            #      retake the target revision again.
            #
            git_svn_trunk_remote_refspec_shorted_token = get_git_svn_trunk_remote_refspec_token(remote_name, shorted = True)
            git_svn_trunk_remote_refspec_token = get_git_svn_trunk_remote_refspec_token(remote_name)

            git_remove_svn_branch(git_svn_trunk_remote_refspec_shorted_token, git_svn_trunk_remote_refspec_token)
            """

            # direct use of the config section name `svn`
            last_pushed_git_svn_commit = fetch_state_ref['last_pushed_git_svn_commit']
            last_pushed_git_svn_commit_rev = last_pushed_git_svn_commit[0]

            git_local_refspec_token = get_git_local_refspec_token(git_local_branch, git_remote_branch)
            git_remote_refspec_token, git_remote_local_refspec_token = \
              get_git_remote_refspec_token_tuple(remote_name, git_local_branch, git_remote_branch)

            git_svn_fetch(last_pushed_git_svn_commit_rev, last_pushed_git_svn_commit_rev, git_svn_fetch_cmdline_list,
              remote_name, git_local_branch,
              git_local_refspec_token, git_remote_refspec_token, last_pruned_git_svn_commit_dict,
              prune_empty_git_svn_commits)

            # revert again if last fetch has broke the HEAD

            # get last pushed commit hash
            git_last_pushed_commit_hash = get_git_last_pushed_commit_hash(git_reporoot, git_remote_local_refspec_token)

            git_reset_if_head_is_not_last_pushed(git_last_pushed_commit_hash, git_local_refspec_token, git_remote_refspec_token,
              reset_hard = reset_hard)

            print('---')

      print('- GIT checkouting...')

      for git_svn_repo_tree_tuple_ref in git_svn_repo_tree_tuple_ref_preorder_list:
        repo_params_ref = git_svn_repo_tree_tuple_ref[0]

        parent_tuple_ref = repo_params_ref['parent_tuple_ref']

        remote_name = repo_params_ref['remote_name']

        parent_git_path_prefix = repo_params_ref['parent_git_path_prefix']

        git_local_branch = repo_params_ref['git_local_branch']
        git_remote_branch = repo_params_ref['git_remote_branch']

        if not parent_tuple_ref is None:
          subtree_git_wcroot = os.path.abspath(os.path.join(git_subtrees_root, remote_name + "'" + parent_git_path_prefix.replace('/', '--'))).replace('\\', '/')

          print(' ->> cwd: `{0}`...'.format(subtree_git_wcroot))
        else:
          print(' ->> cwd: `{0}`...'.format(wcroot_path))

        with conditional(not parent_tuple_ref is None, local.cwd(subtree_git_wcroot) if not parent_tuple_ref is None else None):
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

      if not has_unpushed_svn_revisions_to_update:
        return

      print('- Checking parent-child GIT/SVN repositories for the last fetch state consistency...')

      for git_svn_repo_tree_tuple_ref in git_svn_repo_tree_tuple_ref_preorder_list:
        repo_params_ref = git_svn_repo_tree_tuple_ref[0]

        parent_tuple_ref = repo_params_ref['parent_tuple_ref']
        if not parent_tuple_ref is None:
          parent_repo_params_ref = parent_tuple_ref[0]
          child_repo_params_ref = git_svn_repo_tree_tuple_ref[0]

          # We exclude a compare of GIT repositories has a reference to different SVN repositories, because in that case a child
          # GIT repository (must be already a leaf in the tree in the previous check) is in a read only mode, where the push
          # command is not applicable.

          parent_svn_repo_uuid = parent_repo_params_ref['svn_repo_uuid']
          child_svn_repo_uuid = child_repo_params_ref['svn_repo_uuid']

          child_fetch_state_ref = git_svn_repo_tree_tuple_ref[1]

          # The child git repository can be ahead of parent git repository in case of different uuids of respective svn repositories.
          # In that case the child git repository must be a tree leaf (a builtin check in the `read_git_svn_repo_list` function) and in a read only state.
          if parent_svn_repo_uuid != child_svn_repo_uuid:
            is_child_read_only_repo = child_fetch_state_ref['is_read_only_repo']
            if is_child_read_only_repo != True or not is_child_read_only_repo is True: # double compare to check object id's too!
              raise Exception('the child git repository must be a read only repository: `' + child_repo_params_ref['remote_name'] + '`')
            continue

          parent_fetch_state_ref = parent_tuple_ref[1]

          is_parent_read_only_repo = parent_fetch_state_ref['is_read_only_repo']
          if not is_parent_read_only_repo:
            parent_last_pushed_git_svn_timestamp = parent_fetch_state_ref['last_pushed_git_svn_commit'][2]
            child_unpushed_svn_commit_list = child_fetch_state_ref['unpushed_svn_commit_list']

            # any child git repository should not be behind the parent git repository irrespective to an svn repository uuid
            if not parent_last_pushed_git_svn_timestamp is None and not child_unpushed_svn_commit_list is None:
              child_first_unpushed_svn_commit = child_unpushed_svn_commit_list[0]
              child_first_unpushed_svn_timestamp = child_first_unpushed_svn_commit[2]

              if parent_last_pushed_git_svn_timestamp >= child_first_unpushed_svn_timestamp:
                print('  The parent GIT repository is ahead to the child GIT repository:')

                parent_remote_name = parent_repo_params_ref['remote_name']
                parent_svn_reporoot = parent_repo_params_ref['svn_reporoot']
                parent_svn_path_prefix = parent_repo_params_ref['svn_path_prefix']
                parent_git_local_branch = parent_repo_params_ref['git_local_branch']
                parent_git_remote_branch = parent_repo_params_ref['git_remote_branch']

                child_remote_name = child_repo_params_ref['remote_name']
                child_svn_reporoot = child_repo_params_ref['svn_reporoot']
                child_svn_path_prefix = child_repo_params_ref['svn_path_prefix']

                parent_svn_repopath = parent_svn_reporoot + (('/' + parent_svn_path_prefix) if parent_svn_path_prefix != '' else '')
                child_svn_repopath = child_svn_reporoot + (('/' + child_svn_path_prefix) if child_svn_path_prefix != '' else '')

                child_first_unpushed_svn_date_time = child_first_unpushed_svn_commit[3]

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

                print('  The parent GIT repository must be unpushed back to a commit with the timestamp less than `' +
                  str(child_first_unpushed_svn_timestamp) + '` or before the `' + child_first_unpushed_svn_date_time + '`.')

                print('  These has been pushed commits of the parent GIT repository are ahead to the child repository and they must be unpushed back before continue:')

                parent_git_wcroot = parent_repo_params_ref['git_wcroot']

                with conditional(parent_git_wcroot != '.', local.cwd(parent_git_wcroot)):
                  call_git(['log', '--format=commit: %H%ntimestamp: %at|%ct%ndate_time: %ai|%ci%nauthor: %an <%ae>%n%b',
                    get_git_remote_refspec_token(parent_remote_name, parent_git_local_branch, parent_git_remote_branch),
                    '--since', str(child_first_unpushed_svn_timestamp)], max_stdout_lines = 32)

                raise Exception('the parent GIT repository `' + parent_remote_name + '` is ahead to the child GIT repository `' + child_remote_name + '`')

          """
          child_last_pushed_git_timestamp = child_fetch_state_ref['last_pushed_git_svn_commit'][2]
          parent_unpushed_svn_commit_list = parent_fetch_state_ref['unpushed_svn_commit_list']

          if not child_last_pushed_git_timestamp is None and not parent_unpushed_svn_commit_list is None:
            parent_first_unpushed_svn_commit = parent_unpushed_svn_commit_list[0]
            parent_first_unpushed_svn_timestamp = parent_first_unpushed_svn_commit[2]

            if child_last_pushed_git_timestamp >= parent_first_unpushed_svn_timestamp:
              print('  The child GIT repository is ahead to the parent GIT repository:')

              child_remote_name = child_repo_params_ref['remote_name']
              child_svn_reporoot = child_repo_params_ref['svn_reporoot']
              child_svn_path_prefix = child_repo_params_ref['svn_path_prefix']
              child_git_local_branch = child_repo_params_ref['git_local_branch']
              child_git_remote_branch = child_repo_params_ref['git_remote_branch']

              parent_remote_name = parent_repo_params_ref['remote_name']
              parent_svn_reporoot = parent_repo_params_ref['svn_reporoot']
              parent_svn_path_prefix = parent_repo_params_ref['svn_path_prefix']

              parent_svn_repopath = parent_svn_reporoot + (('/' + parent_svn_path_prefix) if parent_svn_path_prefix != '' else '')
              child_svn_repopath = child_svn_reporoot + (('/' + child_svn_path_prefix) if child_svn_path_prefix != '' else '')

              parent_first_unpushed_svn_date_time = parent_first_unpushed_svn_commit[3]

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

              print('  The child GIT repository must be unpushed back to a commit with the timestamp less than `' +
                str(parent_first_unpushed_svn_timestamp) + '` or before the `' + parent_first_unpushed_svn_date_time + '`.')

              print('  These has been pushed commits of the child GIT repository are ahead to the parent repository and they must be unpushed back before continue:')

              child_git_wcroot = child_repo_params_ref['git_wcroot']

              with conditional(child_git_wcroot != '.', local.cwd(child_git_wcroot)):
                call_git(['log', '--format=commit: %H%ntimestamp: %at|%ct%ndate_time: %ai|%ci%nauthor: %an <%ae>%n%b',
                  get_git_remote_refspec_token(child_remote_name, child_git_local_branch, child_git_remote_branch),
                  '--since', str(parent_first_unpushed_svn_timestamp)], max_stdout_lines = 32)

              raise Exception('the child GIT repository `' + child_remote_name + '` is ahead to the parent GIT repository `' + parent_remote_name + '`')
          """

      # 3.
      #

      max_time_depth_in_multiple_svn_commits_fetch_sec = get_max_time_depth_in_multiple_svn_commits_fetch_sec()

      min_tree_time_of_last_unpushed_svn_commit = get_root_min_tree_time_of_last_unpushed_svn_commit(git_svn_repo_tree_tuple_ref_preorder_list)

      has_unpushed_svn_revisions_to_update = True

      # CAUTION:
      #   1. We must always execute the Algorithm A at least one more time, even if no unpushed svn revisions, because the Algorithm A merges
      #      the children repositories left behind in the Algorithm B!
      #      Read the further detail below.
      #

      # CAUTION: Do-While equivalent!
      while True:
        print('- Collecting latest been pushed git-svn commits and unpushed svn commits...')

        if has_unpushed_svn_revisions_to_update:
          unpushed_svn_commit_by_timestamp_dict = collect_unpushed_svn_revisions_ordered_by_timestamp(git_svn_repo_tree_tuple_ref_preorder_list)
          if not len(unpushed_svn_commit_by_timestamp_dict) > 0:
            unpushed_svn_commit_by_timestamp_dict = None
        else:
          unpushed_svn_commit_by_timestamp_dict = None

        # convert sorted dictionary into the list of tuples to be able to remove items while iterating the list
        unpushed_svn_commit_sorted_by_timestamp_tuple_list = []
        if not unpushed_svn_commit_by_timestamp_dict is None:
          for unpushed_svn_commit_timestamp, unpushed_svn_commit_list in sorted(unpushed_svn_commit_by_timestamp_dict.items()):
            for unpushed_svn_commit_tuple in unpushed_svn_commit_list:
              unpushed_svn_commit_sorted_by_timestamp_tuple_list.append(
                # rev, timestamp, datetime, ref
                (unpushed_svn_commit_tuple[0], unpushed_svn_commit_timestamp, unpushed_svn_commit_tuple[1], unpushed_svn_commit_tuple[2])
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
        #      (unpushed) svn commits.
        #   3.1. If it has the same timestamp as the previously latest been pushed svn
        #        commit(s) with maximum timestamp, then check it on a relation with them
        #        and if the commit is a direct or indirect ancestor to one or more
        #        repositories with the latest been pushed svn commits, then make a merge
        #        the commits between repositories with the latest been pushed svn
        #        commit(s) excluding it and the repository with not yet pushed
        #        (unpushed) svn commit including it (merge it with child repository
        #        subrees).
        #   3.2. If the first commit from the list of not yet pushed (unpushed) svn
        #        commits has no relation to the latest been pushed svn commits with the
        #        same timestamp, then let it be pushed as is in the Algorithm B without
        #        merge it into parent repositories in the algorithm A.
        #   3.3. If the first commit from the list of not yet pushed (unpushed) svn
        #        commits has a greater timestamp, then make a merge the commits between
        #        the latest been pushed svn commit(s) excluding it and the root
        #        repository including it (merge it with child repository subrees).

        # Algorithm B:
        #   After all previously pushed commits is merged into parent repositories in
        #   the algorithm A, the currently pending not yet pushed (unpushed) svn commit
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

            (last_pushed_git_svn_commits_by_max_timestamp_list, last_pushed_git_svn_commit_max_timestamp) = \
              collect_last_pushed_git_svn_commits_by_max_timestamp(git_svn_repo_tree_tuple_ref_preorder_list)

            # CAUTION:
            #   1. We must check on the root repository, because if the list contains the root repository,
            #      then no need to check others, because all commits in the repository tree must be already been pushed without skips.
            #
            if not len(last_pushed_git_svn_commits_by_max_timestamp_list) > 0 or \
               last_pushed_git_svn_commits_by_max_timestamp_list[0][0]['parent_tuple_ref'] is None:
              break

            # 2.
            #

            last_pushed_git_svn_commits_by_max_timestamp_list = \
              remove_git_svn_tree_direct_descendants_from_list(last_pushed_git_svn_commits_by_max_timestamp_list)

            # 3.
            #

            unpushed_svn_commit_is_ancestor_to_commits_in_list = False
            if len(unpushed_svn_commit_sorted_by_timestamp_tuple_list) > 0:
              # rev, timestamp, datetime, ref
              (unpushed_svn_commit_rev, unpushed_svn_commit_timestamp, unpushed_svn_commit_datetime, unpushed_svn_commit_repo_tree_tuple_ref) = \
                unpushed_svn_commit_sorted_by_timestamp_tuple_list[0]

              if last_pushed_git_svn_commit_max_timestamp == unpushed_svn_commit_timestamp: # if equal then already valid versus all minimal timestamps
                unpushed_svn_commit_is_ancestor_to_commits_in_list = \
                  if_git_svn_commit_is_ancestor_to_commits_in_list(unpushed_svn_commit_repo_tree_tuple_ref, last_pushed_git_svn_commits_by_max_timestamp_list)
                if not unpushed_svn_commit_is_ancestor_to_commits_in_list:
                  # 3.2.
                  #
                  break # no need in the Algorithm A, use the Algorithm B
              """
              elif not prune_empty_git_svn_commits and unpushed_svn_commit_timestamp < last_pushed_git_svn_commit_max_timestamp:
                raise Exception('fetch-merge-push sequence is corrupted, the collected unpushed svn commit is earlier by timestamp than the collected pushed git commit')
              """

            # 3.1. + 3.3.
            #

            git_svn_parent_merge_commit_list = []

            for git_svn_repo_tree_tuple_ref in reversed(git_svn_repo_tree_tuple_ref_preorder_list): # in reverse
              if git_svn_repo_tree_tuple_ref in last_pushed_git_svn_commits_by_max_timestamp_list:
                continue
              if if_git_svn_commit_is_ancestor_to_commits_in_list(git_svn_repo_tree_tuple_ref, last_pushed_git_svn_commits_by_max_timestamp_list):
                git_svn_parent_merge_commit_list.append(git_svn_repo_tree_tuple_ref)
              # 3.1. only
              #
              if unpushed_svn_commit_is_ancestor_to_commits_in_list:
                # just quit on the target commit
                if git_svn_repo_tree_tuple_ref is unpushed_svn_commit_repo_tree_tuple_ref:
                  break

            if not len(git_svn_parent_merge_commit_list) > 0:
              raise Exception('fetch-merge-push sequence is corrupted, the collected list of parent repositories to merge is empty')

            # 1. Iterate over a commit children repositories, fetch the associated svn commits and merge them as a subtree into the parent commit.
            # 2. Merge the not yet pushed (unpushed) svn commit with the same timestamp at first as a parent repository changes.
            #

            git_svn_parent_merge_commit_list_size = len(git_svn_parent_merge_commit_list)

            for git_svn_parent_merge_commit_index, git_svn_repo_tree_tuple_ref in enumerate(git_svn_parent_merge_commit_list):
              is_last_parent_merge_commit = True if git_svn_parent_merge_commit_index == git_svn_parent_merge_commit_list_size - 1 else False

              parent_repo_params_ref = git_svn_repo_tree_tuple_ref[0]
              parent_fetch_state_ref = git_svn_repo_tree_tuple_ref[1]

              parent_parent_tuple_ref = parent_repo_params_ref['parent_tuple_ref']
              parent_children_tuple_ref_list = parent_repo_params_ref['children_tuple_ref_list']

              # check on the root repository to stop the Algorithm A
              if is_last_parent_merge_commit and parent_parent_tuple_ref is None:
                collect_multiple_parent_repos_to_merge_and_push = False

              parent_remote_name = parent_repo_params_ref['remote_name']

              parent_svn_reporoot = parent_repo_params_ref['svn_reporoot']
              parent_svn_path_prefix = parent_repo_params_ref['svn_path_prefix']

              parent_svn_repopath = parent_svn_reporoot + (('/' + parent_svn_path_prefix) if parent_svn_path_prefix != '' else '')

              parent_git_local_branch = parent_repo_params_ref['git_local_branch']
              parent_git_remote_branch = parent_repo_params_ref['git_remote_branch']

              parent_parent_git_path_prefix = parent_repo_params_ref['parent_git_path_prefix']

              git_svn_fetch_ignore_paths_regex = parent_repo_params_ref['git_ignore_paths_regex']

              if not parent_parent_tuple_ref is None:
                subtree_git_wcroot = os.path.abspath(os.path.join(git_subtrees_root, parent_remote_name + "'" + parent_parent_git_path_prefix.replace('/', '--'))).replace('\\', '/')

                print(' ->> cwd: `{0}`...'.format(subtree_git_wcroot))
              else:
                print(' ->> cwd: `{0}`...'.format(wcroot_path))

              with conditional(not parent_parent_tuple_ref is None, local.cwd(subtree_git_wcroot) if not parent_parent_tuple_ref is None else None):
                parent_last_pruned_git_svn_commit_dict = parent_fetch_state_ref['last_pruned_git_svn_commit_dict']

                parent_last_pushed_git_svn_commit = parent_fetch_state_ref['last_pushed_git_svn_commit']
                parent_last_pushed_git_svn_commit_rev = parent_last_pushed_git_svn_commit[0]

                is_parent_first_time_push = parent_fetch_state_ref['is_first_time_push']

                # create child branches per last pushed commit from a child repository
                git_fetch_child_subtree_merge_branches(parent_children_tuple_ref_list)

                parent_git_local_refspec_token = get_git_local_refspec_token(parent_git_local_branch, parent_git_remote_branch)
                parent_git_remote_refspec_token = get_git_remote_refspec_token(parent_remote_name, parent_git_local_branch, parent_git_remote_branch)

                ret = call_git_no_except(['show-ref', '--verify', parent_git_local_refspec_token])

                if not ret[0]:
                  # CAUTION:
                  #   1. We have to cleanup before the first `git cherry-pick ...` command, otherwise the command may fail with the messages:
                  #      `error: your local changes would be overwritten by cherry-pick`
                  #      `hint: commit your changes or stash them to proceed.`
                  #   2. We have to reset with the `--hard`, otherwise another error message:
                  #      `error: The following untracked working tree files would be overwritten by merge:`
                  #
                  call_git(['reset', '--hard', parent_git_local_refspec_token])

                # not empty child branches list
                child_subtree_branch_refspec_list = git_get_local_branch_refspec_list('^refs/heads/[^-]+--subtree')

                if child_subtree_branch_refspec_list is None or not len(child_subtree_branch_refspec_list) > 0:
                  raise Exception('fetch-merge-push sequence is corrupted, the children repository branch list is empty')

                reuse_commit_message_refspec_token = None
                reuse_commit_message = None
                reuse_commit_datetime = None

                # ('<prefix>', '<refspec>')
                refspec_merge_tuple_list = []
                child_branch_merge_commit_hash_list = []
                has_parent_refspec_merge_commit = False

                # Collect refspecs w/o merge.
                #

                if unpushed_svn_commit_is_ancestor_to_commits_in_list:
                  # make an svn branch fetch and merge at first as a parent change

                  git_svn_fetch_cmdline_list = []

                  if len(git_svn_fetch_ignore_paths_regex) > 0:
                    git_svn_fetch_cmdline_list.append('--ignore-paths=' + git_svn_fetch_ignore_paths_regex)

                  git_svn_fetch(unpushed_svn_commit_rev, parent_last_pushed_git_svn_commit_rev, git_svn_fetch_cmdline_list,
                    parent_remote_name, parent_git_local_branch,
                    parent_git_local_refspec_token, parent_git_remote_refspec_token, parent_last_pruned_git_svn_commit_dict,
                    prune_empty_git_svn_commits, single_rev = True)

                  # drop fetched svn commit from the list
                  unpushed_svn_commit_sorted_by_timestamp_tuple_list.pop(0)

                  # CAUTION:
                  #   1. We must check whether the revision was really fetched because related fetch directory may not yet/already exist
                  #      (moved/deleted by the svn or completely filtered out by the `--ignore-paths` in the git) and if not, then get
                  #      skip the rebase/cherry-pick/push/<whatever>, otherwise the first or the followed commands may fail on actually
                  #      a not fetched svn commit!
                  #

                  # ignore errors because may call on not yet existed branch
                  git_svn_trunk_remote_refspec_token = get_git_svn_trunk_remote_refspec_token(parent_remote_name)
                  ret = call_git_no_except(['log', '--max-count=1',
                    '--format=commit: %H%ntimestamp: %at|%ct%ndate_time: %ai|%ci%nauthor: %an <%ae>%n%b', git_svn_trunk_remote_refspec_token])

                  git_svn_trunk_first_commit_svn_rev, git_svn_trunk_first_commit_hash, \
                  git_svn_trunk_first_commit_author_timestamp, git_svn_trunk_first_commit_author_date_time, \
                  git_svn_trunk_first_commit_timestamp, git_svn_trunk_first_commit_date_time = \
                    get_git_first_commit_from_git_log(ret[1].rstrip())

                  has_parent_refspec_merge_commit = (git_svn_trunk_first_commit_svn_rev == unpushed_svn_commit_rev)
                  if has_parent_refspec_merge_commit:
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
                    ##  1. call_git(['svn', 'rebase', '-l'])
                    ##  2. git_local_refspec_token = get_git_local_refspec_token(parent_git_local_branch, parent_git_remote_branch)
                    ##     call_git(['rebase', git_local_refspec_token, 'refs/remotes/origin/git-svn-trunk'])
                    ##  3. call_git(['cherry-pick', '--allow-empty', '--no-commit', '-X', 'subtree=' + child_parent_git_path_prefix, child_branch_refspec])
                    ##  4. call_git(['pull', '--no-edit', '--no-commit', '--allow-unrelated-histories', '-s', 'subtree', '-Xsubtree=' + child_parent_git_path_prefix + '/', child_git_pull_refspec_token])

                    if retain_commmit_git_svn_parents:
                      refspec_merge_tuple_list.append((None, git_svn_trunk_remote_refspec_token))
                    reuse_commit_message_refspec_token = git_svn_trunk_remote_refspec_token
                    reuse_commit_datetime = unpushed_svn_commit_datetime
                  else:
                    print('- The svn commit merge from a parent repository is skipped, the respective svn commit revision was not found as the last fetched: fetched=' +
                      str(unpushed_svn_commit_rev) + ' first_found=' + str(git_svn_trunk_first_commit_svn_rev))

                git_svn_child_merge_commit_list_size = len(parent_children_tuple_ref_list)

                if not git_svn_child_merge_commit_list_size > 0:
                  raise Exception('fetch-merge-push sequence is corrupted, the parent repository does not have a child repository')

                max_child_git_svn_commit_rev = 0          # must be 0 instead of None
                max_child_git_svn_commit_timestamp = None
                max_child_git_svn_commit_datetime = None

                """
                for git_svn_child_merge_commit_index, child_tuple_ref in enumerate(parent_children_tuple_ref_list):
                  is_last_child_merge_commit = True if git_svn_child_merge_commit_index == git_svn_child_merge_commit_list_size - 1 else False
                """
                for child_tuple_ref in parent_children_tuple_ref_list:
                  child_repo_params_ref = child_tuple_ref[0]
                  child_fetch_state_ref = child_tuple_ref[1]

                  child_remote_name = child_repo_params_ref['remote_name']

                  child_git_local_branch = child_repo_params_ref['git_local_branch']
                  child_git_remote_branch = child_repo_params_ref['git_remote_branch']

                  child_branch_refspec = 'refs/heads/' + child_remote_name + '--subtree'

                  # filter out empty branches
                  if child_branch_refspec in child_subtree_branch_refspec_list:
                    child_parent_git_path_prefix = child_repo_params_ref['parent_git_path_prefix']

                    refspec_merge_tuple_list.append((child_parent_git_path_prefix + '/', child_branch_refspec))

                    child_branch_merge_commit_hash = get_git_local_head_commit_hash(child_branch_refspec)
                    child_branch_merge_commit_hash_list.append(child_branch_merge_commit_hash)

                    child_last_pushed_git_svn_commit = child_fetch_state_ref['last_pushed_git_svn_commit']
                    child_last_pushed_git_svn_commit_rev = child_last_pushed_git_svn_commit[0]
                    child_last_pushed_git_svn_commit_timestamp = child_last_pushed_git_svn_commit[2]
                    child_last_pushed_git_svn_commit_datetime = child_last_pushed_git_svn_commit[3]

                    if max_child_git_svn_commit_rev < child_last_pushed_git_svn_commit_rev:
                      max_child_git_svn_commit_rev = child_last_pushed_git_svn_commit_rev
                      max_child_git_svn_commit_timestamp = child_last_pushed_git_svn_commit_timestamp
                      max_child_git_svn_commit_datetime = child_last_pushed_git_svn_commit_datetime

                    if reuse_commit_message_refspec_token is None:
                      reuse_commit_message_refspec_token = child_branch_refspec
                      reuse_commit_datetime = child_last_pushed_git_svn_commit_datetime

                      # replace value of the `git-svn-id` token in the commit message (a child svn repository token) by a parent svn repostiory token
                      ret = call_git(['log', '--max-count=1', '--format=%B', reuse_commit_message_refspec_token])
                      reuse_commit_message = ret[1].rstrip()
                      reuse_commit_message = \
                        re.sub(r'^git-svn-id:\s[^@]+@(\d+)\s[^\n\r]+$', 'git-svn-id: ' + parent_svn_repopath + r'@\1 ' + svn_repo_root_to_uuid_dict[parent_svn_reporoot],
                          reuse_commit_message, count = 1, flags = re.MULTILINE)

                if not max_child_git_svn_commit_rev > 0:
                  raise Exception('fetch-merge-push sequence is corrupted, no one child repository branch is merged')

                # Start merge collected refspecs w/o commit them.
                #

                # CAUTION:
                #   The `-no-ff` parameter should not use in case of merge into empty head, otherwise:
                #   `fatal: Non-fast-forward commit does not make sense into an empty head`
                #
                if len(refspec_merge_tuple_list) > 0:
                  call_git(['merge', '--allow-unrelated-histories', '--no-edit', '--no-commit', '-s', 'ours'] +
                    [refspec for prefix, refspec in refspec_merge_tuple_list] +
                    [child_branch_merge_commit_hash for child_branch_merge_commit_hash in child_branch_merge_commit_hash_list])

                # Merge collected refspecs with prefixes into local index.
                #

                for prefix, refspec in refspec_merge_tuple_list:
                  if not prefix is None:
                    # WORKAROUND:
                    #   To workaround an issue with the error message `error: Entry '<prefix>/...' overlaps with '<prefix>/...'.  Cannot bind.`
                    #   we have to entirely remove the prefix directory from the working copy at first!
                    #   Based on: `git read-tree failure` : https://groups.google.com/d/msg/git-users/l0BKlv0EFKw/AvFEFXgX6vMJ
                    #
                    call_git_no_except(['rm', '--cached', '-r', prefix])

                    call_git(['read-tree', '--prefix=' + prefix, refspec])
                  else:
                    call_git(['read-tree', refspec])

                # Commit the local index with the mainline commit message reuse.
                #

                # Change and make a commit:
                #   1. Author name and email.
                #   2. Commit date.
                #
                author_svn_token = yaml_expand_global_string('${${SCM_TOKEN}.USER} <${${SCM_TOKEN}.EMAIL}>')

                if reuse_commit_message is None:
                  call_git(['commit', '--no-edit', '--allow-empty', '--author=' + author_svn_token, '--date', reuse_commit_datetime, '-C', reuse_commit_message_refspec_token])
                else:
                  with tkl.TmpFileIO('w+t') as stdin_iostr:
                    stdin_iostr.write(reuse_commit_message)
                    stdin_iostr.flush() # otherwise would be an empty commit message
                    # WORKAROUND:
                    #   Temporary workwound, based on:
                    #   ``plumbum.local['...'].run(stdin = myobj)` ignores stdin as a not empty temporary file` : https://github.com/tomerfiliba/plumbum/issues/487
                    #
                    with open(stdin_iostr.path, 'rt') as stdin_file:
                      call_git(['commit', '--no-edit', '--allow-empty', '--author=' + author_svn_token, '--date', reuse_commit_datetime, '-F', '-'], stdin = stdin_file)

                ret = call_git(['rev-parse', 'HEAD'])
                parent_head_git_commit_hash = ret[1].rstrip()

                if not len(parent_head_git_commit_hash) > 0:
                  raise Exception('HEAD commit does not exist')

                """
                call_git(['update-ref', parent_git_local_refspec_token, parent_head_git_commit_hash])
                """

                parent_git_push_refspec_token = get_git_push_refspec_token(parent_git_local_branch, parent_git_remote_branch)

                if not is_parent_first_time_push:
                  call_git(['push', parent_remote_name, parent_git_push_refspec_token])
                else:
                  call_git(['push', '-u', parent_remote_name, parent_git_push_refspec_token])
                  parent_fetch_state_ref['is_first_time_push'] = False

                # update last pushed git/svn commit
                parent_fetch_state_ref['last_pushed_git_svn_commit'] = \
                  (max_child_git_svn_commit_rev, parent_head_git_commit_hash, max_child_git_svn_commit_timestamp, max_child_git_svn_commit_datetime)

                # remove all subtree merge branches
                git_remove_child_subtree_merge_branches(parent_children_tuple_ref_list)

                # CAUTION:
                #   We have to reset the working directory after the push to avoid next merge problems after merge from multiple child branches.
                #   Otherwise the `git rm ....` command above can fail with the message: `fatal: pathspec '<prefix>' did not match any files`
                #
                call_git(['reset', '--hard', parent_git_local_branch])

          # === Algorithm B ===
          #

          print('- GIT-SVN single pushing is started.')

          if len(unpushed_svn_commit_sorted_by_timestamp_tuple_list) > 0:
            # rev, timestamp, datetime, ref
            (unpushed_svn_commit_rev, unpushed_svn_commit_timestamp, unpushed_svn_commit_datetime, unpushed_svn_commit_repo_tree_tuple_ref) = \
              unpushed_svn_commit_sorted_by_timestamp_tuple_list.pop(0)

            repo_params_ref = unpushed_svn_commit_repo_tree_tuple_ref[0]
            fetch_state_ref = unpushed_svn_commit_repo_tree_tuple_ref[1]

            remote_name = repo_params_ref['remote_name']

            children_tuple_ref_list = repo_params_ref['children_tuple_ref_list']

            min_ro_tree_time_of_first_unpushed_svn_commit = get_subtree_min_ro_tree_time_of_first_unpushed_svn_commit(unpushed_svn_commit_repo_tree_tuple_ref)

            if not min_ro_tree_time_of_first_unpushed_svn_commit is None:
              min_ro_tree_time_of_first_unpushed_svn_commit_timestamp = min_ro_tree_time_of_first_unpushed_svn_commit[0]

              if unpushed_svn_commit_timestamp >= min_ro_tree_time_of_first_unpushed_svn_commit_timestamp:
                min_ro_tree_svn_commit_repo_tree_tuple_ref = min_ro_tree_time_of_first_unpushed_svn_commit[2]
                min_ro_tree_repo_params_ref = min_ro_tree_svn_commit_repo_tree_tuple_ref[0]
                min_ro_tree_remote_name = min_ro_tree_repo_params_ref['remote_name']
                raise Exception('The `' + min_ro_tree_remote_name +
                  '` read only repository must be pushed from svn in another project before continue with the current project')

            if not min_tree_time_of_last_unpushed_svn_commit is None:
              min_tree_time_of_last_unpushed_svn_commit_timestamp = min_tree_time_of_last_unpushed_svn_commit[0]

              if min_tree_time_of_last_unpushed_svn_commit_timestamp < unpushed_svn_commit_timestamp:
                break

            parent_tuple_ref = repo_params_ref['parent_tuple_ref']

            svn_reporoot = repo_params_ref['svn_reporoot']

            git_local_branch = repo_params_ref['git_local_branch']
            git_remote_branch = repo_params_ref['git_remote_branch']

            parent_git_path_prefix = repo_params_ref['parent_git_path_prefix']

            git_svn_fetch_ignore_paths_regex = repo_params_ref['git_ignore_paths_regex']

            if not parent_tuple_ref is None:
              subtree_git_wcroot = os.path.abspath(os.path.join(git_subtrees_root, remote_name + "'" + parent_git_path_prefix.replace('/', '--'))).replace('\\', '/')

              print(' ->> cwd: `{0}`...'.format(subtree_git_wcroot))
            else:
              print(' ->> cwd: `{0}`...'.format(wcroot_path))

            with conditional(not parent_tuple_ref is None, local.cwd(subtree_git_wcroot) if not parent_tuple_ref is None else None):
              last_pruned_git_svn_commit_dict = fetch_state_ref['last_pruned_git_svn_commit_dict']

              # create child branches per last pushed commit from a child repository
              git_fetch_child_subtree_merge_branches(children_tuple_ref_list)

              git_svn_fetch_cmdline_list = []

              if len(git_svn_fetch_ignore_paths_regex) > 0:
                git_svn_fetch_cmdline_list.append('--ignore-paths=' + git_svn_fetch_ignore_paths_regex)

              last_pushed_git_svn_commit = fetch_state_ref['last_pushed_git_svn_commit']
              last_pushed_git_svn_commit_rev = last_pushed_git_svn_commit[0]

              is_first_time_push = fetch_state_ref['is_first_time_push']

              git_local_refspec_token = get_git_local_refspec_token(git_local_branch, git_remote_branch)
              git_remote_refspec_token = get_git_remote_refspec_token(remote_name, git_local_branch, git_remote_branch)

              git_svn_fetch(unpushed_svn_commit_rev, last_pushed_git_svn_commit_rev, git_svn_fetch_cmdline_list,
                remote_name, git_local_branch,
                git_local_refspec_token, git_remote_refspec_token, last_pruned_git_svn_commit_dict,
                prune_empty_git_svn_commits, single_rev = True)

              # CAUTION:
              #   1. We must check whether the revision was really fetched because related fetch directory may not yet/already exist
              #      (moved/deleted by the svn or completely filtered out by the `--ignore-paths` in the git) and if not, then get
              #      skip the rebase/cherry-pick/push/<whatever>, otherwise the first or the followed commands may fail on actually
              #      a not fetched svn commit!
              #

              # ignore errors because may call on not yet existed branch
              git_svn_trunk_remote_refspec_token = get_git_svn_trunk_remote_refspec_token(remote_name)
              ret = call_git_no_except(['log', '--max-count=1',
                '--format=commit: %H%ntimestamp: %at|%ct%ndate_time: %ai|%ci%nauthor: %an <%ae>%n%b', git_svn_trunk_remote_refspec_token])

              git_svn_trunk_first_commit_svn_rev, git_svn_trunk_first_commit_hash, \
              git_svn_trunk_first_commit_author_timestamp, git_svn_trunk_first_commit_author_date_time, \
              git_svn_trunk_first_commit_timestamp, git_svn_trunk_first_commit_date_time = \
                get_git_first_commit_from_git_log(ret[1].rstrip())
              if git_svn_trunk_first_commit_svn_rev == unpushed_svn_commit_rev:
                # the fetched svn revision is confirmed, can continue now

                # CAUTION:
                #   In the git a child repository branch must be always merged into a parent repository even if was merged for a previous svn revision(s),
                #   otherwise a parent repository commit won't contain changes made in a child repository in previous svn revisions.
                #
                # ('<prefix>', '<refspec>')
                child_refspec_merge_tuple_list = []
                child_branch_merge_commit_hash_list = []

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

                      child_refspec_merge_tuple_list.append((child_parent_git_path_prefix + '/', child_branch_refspec))

                      child_branch_merge_commit_hash = get_git_local_head_commit_hash(child_branch_refspec)
                      child_branch_merge_commit_hash_list.append(child_branch_merge_commit_hash)

                # CAUTION:
                #   1. The `git svn rebase ...` can not handle unrelated histories properly, we have to use plain `git rebase ...` to handle that.
                #   2. We can not use `git rebase ...` too because the `git-svn-trunk` branch can be incomplete and consist only of a single
                #      and the last one commit which can involve incorrect rebase with an error message around a fall back rebase:
                #      `patching base and 3-way merge`.
                #   3. Additionally, the `git rebase ...` can skip commits and make no action even if commits exists, so we have to track that behaviour.
                #   4. We can not use `git cherry-pick ...` too because of absence of the merge metadata (single commit parent instead of multiple) in
                #      case of multiple child repository merge.
                #   5. Additionally, the `git cherry-pick ...` can not handle a subtree prefix and merges all commits into the root directory of a commit.
                #
                #   To resolve all of these we have to use:
                #   1. `git merge ...` command without the `--no-commit` parameter to merge commit as a main commit.
                #
                ##  1. call_git(['svn', 'rebase', '-l'])
                ##  2. git_local_refspec_token = get_git_local_refspec_token(git_local_branch, git_remote_branch)
                ##     call_git(['rebase', git_local_refspec_token, 'refs/remotes/origin/git-svn-trunk'])
                ##  3. call_git(['cherry-pick', '--allow-empty', git_svn_trunk_first_commit_hash])

                ret = call_git_no_except(['show-ref', '--verify', git_local_refspec_token])

                if not ret[0]:
                  # CAUTION:
                  #   1. We have to cleanup before the `git cherry-pick ...` command, otherwise the command may fail with the messages:
                  #      `error: your local changes would be overwritten by cherry-pick`
                  #      `hint: commit your changes or stash them to proceed.`
                  #   2. We have to reset with the `--hard`, otherwise another error message:
                  #      `error: The following untracked working tree files would be overwritten by merge:`
                  #
                  call_git(['reset', '--hard', git_local_refspec_token])

                # CAUTION:
                #   We should not use `git merge ...` commad in case when the HEAD is detached, otherwise the merge
                #   will assign the HEAD to the source branch BEFORE a merge!
                #   So, a merged commit would be empty because the source branch commit would merge on top of it's own.
                #

                # check if HEAD is not pointing to the source branch
                """
                if head_git_commit_hash != git_svn_trunk_first_commit_hash:
                """
                # Start merge a commit w/o merge it to retain the merge parent list.
                #

                # CAUTION:
                #   The `-no-ff` parameter should not use in case of merge into empty head, otherwise:
                #   `fatal: Non-fast-forward commit does not make sense into an empty head`
                #
                if retain_commmit_git_svn_parents:
                  call_git(['merge', '--allow-unrelated-histories', '--no-edit', '--no-commit', '-s', 'ours', git_svn_trunk_remote_refspec_token] +
                    [refspec for prefix, refspec in child_refspec_merge_tuple_list] +
                    [child_branch_merge_commit_hash for child_branch_merge_commit_hash in child_branch_merge_commit_hash_list])
                elif len(child_refspec_merge_tuple_list) > 0:
                  call_git(['merge', '--allow-unrelated-histories', '--no-edit', '--no-commit', '-s', 'ours'] +
                    [refspec for prefix, refspec in child_refspec_merge_tuple_list] +
                    [child_branch_merge_commit_hash for child_branch_merge_commit_hash in child_branch_merge_commit_hash_list])

                # Merge a parent commit into local index.
                #

                call_git(['read-tree', git_svn_trunk_remote_refspec_token])

                # Merge collected child refspecs with prefixes into local index.
                #

                for prefix, refspec in child_refspec_merge_tuple_list:
                  if not prefix is None:
                    # WORKAROUND:
                    #   To workaround an issue with the error message `error: Entry '<prefix>/...' overlaps with '<prefix>/...'.  Cannot bind.`
                    #   we have to entirely remove the prefix directory from the working copy at first!
                    #   Based on: `git read-tree failure` : https://groups.google.com/d/msg/git-users/l0BKlv0EFKw/AvFEFXgX6vMJ
                    #
                    call_git_no_except(['rm', '--cached', '-r', prefix])

                    call_git(['read-tree', '--prefix=' + prefix, refspec])
                  else:
                    call_git(['read-tree', refspec])

                # Commit the local index with the mainline commit message reuse.
                #

                # Change and make a commit:
                #   1. Author name and email.
                #   2. Commit date.
                #
                author_svn_token = yaml_expand_global_string('${${SCM_TOKEN}.USER} <${${SCM_TOKEN}.EMAIL}>')
                call_git(['commit', '--allow-empty', '--no-edit', '--author=' + author_svn_token, '--date', unpushed_svn_commit_datetime,
                  '-C', git_svn_trunk_remote_refspec_token])

                ret = call_git(['rev-parse', 'HEAD'])
                head_git_commit_hash = ret[1].rstrip()

                if not len(head_git_commit_hash) > 0:
                  raise Exception('HEAD commit does not exist')

                """
                if head_git_commit_hash != git_svn_trunk_first_commit_hash:
                  git_local_refspec_token = get_git_local_refspec_token(git_local_branch, git_remote_branch)
                  call_git(['update-ref', git_local_refspec_token, head_git_commit_hash])
                """

                git_push_refspec_token = get_git_push_refspec_token(git_local_branch, git_remote_branch)

                if not is_first_time_push:
                  call_git(['push', remote_name, git_push_refspec_token])
                else:
                  call_git(['push', '-u', remote_name, git_push_refspec_token])
                  fetch_state_ref['is_first_time_push'] = False

                # update last pushed git/svn commit
                fetch_state_ref['last_pushed_git_svn_commit'] = \
                  (unpushed_svn_commit_rev, head_git_commit_hash, unpushed_svn_commit_timestamp, unpushed_svn_commit_datetime)
              else:
                print('- The push is skipped, the respective svn commit revision was not found as the last fetched: fetched=' +
                  str(unpushed_svn_commit_rev) + ' first_found=' + str(git_svn_trunk_first_commit_svn_rev))

          if not len(unpushed_svn_commit_sorted_by_timestamp_tuple_list) > 0:
            break

        has_unpushed_svn_revisions_to_update = \
          update_git_svn_repo_fetch_state(git_svn_repo_tree_tuple_ref_preorder_list, max_time_depth_in_multiple_svn_commits_fetch_sec, is_first_time_update = False)
        if not has_unpushed_svn_revisions_to_update:
          break

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

  print(' ->> wcroot: `{0}`'.format(wcroot_path))

  if not os.path.exists(wcroot_path):
    os.mkdir(wcroot_path)

  with local.cwd(wcroot_path), GitReposListReader(configure_dir + '/git_repos.lst') as git_repos_reader, ServiceProcCache() as svc_proc_cache:
    executed_procs = cache_init_service_proc(svc_proc_cache)

    with tkl.OnExit(lambda: cache_close_running_procs(executed_procs, svc_proc_cache)):
      column_names, column_widths = get_git_svn_repos_list_table_params()

      if git_subtrees_root is None:
        git_subtrees_root = wcroot_path + '/.git/svn2git/gitwc'

      git_svn_repo_tree_dict, git_svn_repo_tree_tuple_ref_preorder_list, svn_repo_root_to_uuid_dict = \
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

      remote_name = repo_params_ref['remote_name']

      git_reporoot = repo_params_ref['git_reporoot']
      svn_reporoot = repo_params_ref['svn_reporoot']

      parent_git_path_prefix = repo_params_ref['parent_git_path_prefix']
      svn_path_prefix = repo_params_ref['svn_path_prefix']

      git_local_branch = repo_params_ref['git_local_branch']
      git_remote_branch = repo_params_ref['git_remote_branch']

      if not parent_tuple_ref is None:
        subtree_git_wcroot = os.path.abspath(os.path.join(git_subtrees_root, remote_name + "'" + parent_git_path_prefix.replace('/', '--'))).replace('\\', '/')

        print(' ->> cwd: `{0}`...'.format(subtree_git_wcroot))
      else:
        print(' ->> cwd: `{0}`...'.format(wcroot_path))

      with conditional(not parent_tuple_ref is None, local.cwd(subtree_git_wcroot) if not parent_tuple_ref is None else None):
        print('- GIT searching...')

        if not svn_rev is None:
          # find a particular revision
          git_last_svn_rev, git_commit_hash, \
          git_commit_author_timestamp, git_commit_author_date_time, \
          git_commit_timestamp, git_commit_date_time, \
          num_overall_git_commits = \
            get_last_git_svn_commit_by_git_log(remote_name, git_local_branch, git_remote_branch, svn_reporoot, svn_path_prefix, svn_rev)
        else:
          # get the last commit revision
          git_last_svn_rev, git_commit_hash, \
          git_commit_author_timestamp, git_commit_author_date_time, \
          git_commit_timestamp, git_commit_date_time, \
          num_overall_git_commits = \
            get_last_git_svn_rev_by_git_log(remote_name, git_local_branch, git_remote_branch, svn_reporoot, svn_path_prefix)

        if not git_last_svn_rev > 0 and num_overall_git_commits > 0:
          raise Exception('svn revision is not found in the git log output: rev={0} path=`{1}`'.format(svn_rev, svn_reporoot + '/' +svn_path_prefix))

        print('- GIT checkouting...')

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
        svn_subtrees_root = wcroot_path + '/.git/svn2git/svnwc'

      subtree_svn_dir = remote_name + "'" + svn_path_prefix.replace('/', '--')
      subtree_svn_wcroot = os.path.abspath(os.path.join(svn_subtrees_root, subtree_svn_dir)).replace('\\', '/')

      if not os.path.exists(subtree_svn_wcroot):
        print('>mkdir: -p ' + subtree_svn_wcroot)
        try:
          os.makedirs(subtree_svn_wcroot)
        except FileExistsError:
          pass

      print(' ->> cwd: `{0}`...'.format(subtree_svn_wcroot))

      with local.cwd(subtree_svn_wcroot):
        print('- SVN checkouting...')

        svn_repopath = svn_reporoot + (('/' + svn_path_prefix) if svn_path_prefix != '' else '')

        if not os.path.exists('.svn'):
          # shift current directory up to make svn checkout
          with local.cwd('..'):
            call_svn(['co', '-r' + str(git_last_svn_rev), '--ignore-externals', svn_repopath, subtree_svn_dir])
        else:
          # shift current directory up to show the subdirectory
          with local.cwd('..'):
            call_svn(['up', '-r' + str(git_last_svn_rev), '--ignore-externals', subtree_svn_dir])

      print('- GIT-SVN comparing...')
