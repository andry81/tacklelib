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

  reserved_branches_startswith = ['git-svn']

  for reserved_branch in reserved_branches_startswith:
    if git_local_branch.startswith(reserved_branch):
      raise Exception('git_local_branch value is internally reserved from usage: `' + git_local_branch + '`')
    if git_remote_branch.startswith(reserved_branch):
      raise Exception('git_remote_branch value is internally reserved from usage: `' + git_remote_branch + '`')

  if git_local_branch != '' and git_remote_branch == '':
    git_remote_branch = git_local_branch
  elif git_local_branch == '' and git_remote_branch != '':
    git_local_branch = git_remote_branch
  elif git_local_branch == '' and git_remote_branch == '':
    raise Exception("at least one of git_local_branch and git_remote_branch parameters must be a valid branch name")

  return (git_local_branch, git_remote_branch)

def get_git_local_refspec_token(git_local_branch, git_remote_branch):
  return 'refs/heads/' + validate_git_refspec(git_local_branch, git_remote_branch)[0]

def get_git_remote_refspec_token(remote_name, git_local_branch, git_remote_branch):
  return 'refs/remotes/' + remote_name + '/' + validate_git_refspec(git_local_branch, git_remote_branch)[1]

def get_git_remote_refspec_token_tuple(remote_name, git_local_branch, git_remote_branch):
  git_local_branch, git_remote_branch = validate_git_refspec(git_local_branch, git_remote_branch)

  return ('refs/remotes/' + remote_name + '/' + git_remote_branch, 'refs/heads/' + git_remote_branch)

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

def git_remove_svn_branch(svn_branch, remote_refspec_token):
  # remove entire branch and the index
  call_git_no_except(['branch', '-D', '-r', svn_branch])
  remove_dir = '.git/svn/' + remote_refspec_token
  if os.path.exists('.git/svn/' + remote_refspec_token):
    print('- removing directory: `' + remove_dir + '`')
    shutil.rmtree('.git/svn/' + remote_refspec_token)

def register_git_remotes(git_repos_reader, scm_name, remote_name, with_root):
  git_repos_reader.reset()

  if with_root:
    for root_row in git_repos_reader:
      if root_row['scm_token'] == scm_name and root_row['remote_name'] == remote_name:
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
    if subtree_row['scm_token'] == scm_name and subtree_row['parent_remote_name'] == remote_name:
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

def git_fetch_subtrees(git_repos_reader, scm_name, remote_name):
  git_repos_reader.reset()

  for subtree_row in git_repos_reader:
    if subtree_row['scm_token'] == scm_name and subtree_row['parent_remote_name'] == remote_name:
      subtree_remote_name = subtree_row['remote_name']
      subtree_git_reporoot = yaml_expand_global_string(subtree_row['git_reporoot'])
      subtree_git_local_branch = yaml_expand_global_string(subtree_row['git_local_branch'])
      subtree_git_remote_branch = yaml_expand_global_string(subtree_row['git_remote_branch'])
      subtree_parent_git_path_prefix = subtree_row['parent_git_path_prefix']

      if subtree_parent_git_path_prefix == '.':
        raise Exception('not root branch type must have not empty git parent path prefix')

      # expand if contains a variable substitution
      subtree_parent_git_path_prefix = yaml_expand_global_string(subtree_parent_git_path_prefix)

      git_subtree_cmdline = subtree_row['git_subtree_cmdline']
      if git_subtree_cmdline == '.':
        git_subtree_cmdline = ''
      else:
        git_subtree_cmdline = yaml_expand_global_string(git_subtree_cmdline)

      # CAUTION:
      #   We can not simply call to `git subtree add ...` here as long as it would return `prefix '...' already exists` error.
      #   Instead we must take changes into a separate branch and merge them into main branch like introduced here:
      #   https://github.com/MCUdude/MCUdude_corefiles/issues/5
      #   https://stackoverflow.com/questions/17842966/how-can-i-create-a-gitsubtree-of-an-existing-repository/27432237#27432237
      #

      subtree_local_tmp_branch = subtree_remote_name + '--subtree-tmp'

      # cleanup through remove entire branch
      call_git_no_except(['branch', '-D', subtree_local_tmp_branch])

      subtree_git_remote_refspec_token, subtree_git_remote_local_refspec_token = \
        get_git_remote_refspec_token_tuple(subtree_remote_name, subtree_git_local_branch, subtree_git_remote_branch)

      # get last pushed commit hash
      subtree_git_last_pushed_commit_hash = get_git_last_pushed_commit_hash(subtree_git_reporoot, subtree_git_remote_local_refspec_token)

      if not subtree_git_last_pushed_commit_hash is None:
        # fetch remote branch into temporary local branch
        subtree_remote_tmp_branch = validate_git_refspec(subtree_git_local_branch, subtree_git_remote_branch)[1]

        call_git(['fetch', subtree_remote_name, subtree_remote_tmp_branch + ':refs/heads/' + subtree_local_tmp_branch])

def git_remove_subtree_branches(git_repos_reader, scm_name, remote_name):
  git_repos_reader.reset()

  for subtree_row in git_repos_reader:
    if subtree_row['scm_token'] == scm_name and subtree_row['parent_remote_name'] == remote_name:
      subtree_remote_name = subtree_row['remote_name']

      subtree_local_tmp_branch = subtree_remote_name + '--subtree-tmp'

      call_git_no_except(['branch', '-D', subtree_local_tmp_branch])

# ex: `git checkout -b <git_local_branch> refs/remotes/origin/<git_remote_branch>`
#
def get_git_switch_branch_args_list(remote_name, git_local_branch, git_remote_branch):
  git_local_branch = validate_git_refspec(git_local_branch, git_remote_branch)[0]
  return ['-c', git_local_branch, get_git_local_refspec_token(git_local_branch, git_remote_branch)]

"""
# ex: `git checkout -b <git_local_branch> refs/remotes/origin/<git_remote_branch>`
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

  for row in io.StringIO(ret[1]):
    first_commit_hash = row
    break

  return first_commit_hash.strip()
"""

# Returns only the first git commit parameters or nothing.
#
def get_git_first_commit_from_git_log(str):
  svn_rev = None
  commit_hash = None
  commit_timestamp = None

  # To iterate over lines instead chars.
  # (see details: https://stackoverflow.com/questions/3054604/iterate-over-the-lines-of-a-string/3054898#3054898 )

  lines = io.StringIO(str)
  for line in lines:
    value_list = [value.strip() for value in line.split(":", 1)]
    key = value_list[0]
    if key == 'commit':
      if not commit_hash is None:
        # return the previous one
        return (svn_rev, commit_hash, commit_timestamp)
      commit_hash = value_list[1]
    elif key == 'timestamp':
      commit_timestamp = value_list[1]
    elif key == 'git-svn-id':
      git_svn_url = value_list[1].split(' ', 1)[0]
      svn_rev_index = git_svn_url.rfind('@')
      if svn_rev_index > 0:
        svn_path = git_svn_url[:svn_rev_index]
        svn_rev = int(git_svn_url[svn_rev_index + 1:])

  return (svn_rev, commit_hash, commit_timestamp)

# Returns the git commit parameters where was found the svn revision under the requested remote svn url, otherwise would return the last commit parameters.
#
def get_git_commit_from_git_log(str, svn_reporoot, svn_path_prefix):
  if svn_path_prefix == '.': svn_path_prefix = ''

  svn_remote_path = svn_reporoot + ('/' + svn_path_prefix if svn_path_prefix != '' else '')

  num_commits = 0

  # To iterate over lines instead chars.
  # (see details: https://stackoverflow.com/questions/3054604/iterate-over-the-lines-of-a-string/3054898#3054898 )

  lines = io.StringIO(str)
  for line in lines:
    print(line.strip())
    value_list = [value.strip() for value in line.split(":", 1)]
    key = value_list[0]
    if key == 'commit':
      commit_hash = value_list[1]
      num_commits += 1
    elif key == 'timestamp':
      commit_timestamp = int(value_list[1])
    elif key == 'date_time':
      commit_date_time = value_list[1]
    elif key == 'git-svn-id':
      git_svn_url = value_list[1].split(' ', 1)[0]
      svn_rev_index = git_svn_url.rfind('@')
      if svn_rev_index > 0:
        svn_path = git_svn_url[:svn_rev_index]
        svn_rev = int(git_svn_url[svn_rev_index + 1:])

        svn_path_wo_scheme = tkl.ParseResult('', *tkl.urlparse(svn_path)[1:]).geturl()
        svn_remote_path_wo_scheme = tkl.ParseResult('', *tkl.urlparse(svn_remote_path)[1:]).geturl()

        if svn_path_wo_scheme == svn_remote_path_wo_scheme:
          return (svn_rev, commit_hash, commit_timestamp, commit_date_time, num_commits)

  return (0, None, None, None, num_commits)

def get_git_last_pushed_commit_hash(git_reporoot, git_remote_local_refspec_token):
  git_last_pushed_commit_hash = None

  ret = call_git(['ls-remote', git_reporoot])

  with GitLsRemoteListReader(ret[1]) as git_ls_remote_reader:
    for row in git_ls_remote_reader:
      if row['ref'] == git_remote_local_refspec_token:
        git_last_pushed_commit_hash = row['hash']
        break

  return git_last_pushed_commit_hash

def get_git_fetch_head_commit_hash(git_remote_refspec_token, verify_ref = True):
  git_fetch_head_commit_hash = None

  ret = call_git(['show-ref'] + (['--verify'] if verify_ref else []) + [git_remote_refspec_token])

  with GitShowRefListReader(ret[1]) as git_show_ref_reader:
    for row in git_show_ref_reader:
      if row['ref'] == git_remote_refspec_token:
        git_fetch_head_commit_hash = row['hash'].rstrip()
        break

  if not git_fetch_head_commit_hash is None:
    print(git_fetch_head_commit_hash)

  return git_fetch_head_commit_hash

def get_git_head_commit_hash(git_local_refspec_token, verify_ref = True):
  git_head_commit_hash = None

  ret = call_git_no_except(['show-ref'] + (['--verify'] if verify_ref else []) + [git_local_refspec_token])

  with GitShowRefListReader(ret[1]) as git_show_ref_reader:
    for row in git_show_ref_reader:
      if row['ref'] == git_local_refspec_token:
        git_head_commit_hash = row['hash'].rstrip()
        break

  if not git_head_commit_hash is None:
    print(git_head_commit_hash)

  return git_head_commit_hash

def revert_if_git_head_refs_is_not_last_pushed(git_last_pushed_commit_hash, git_local_refspec_token, git_remote_refspec_token,
                                               verify_head_ref = True, reset_hard = False):
  # compare the last pushed commit hash with the last fetched commit hash and if different, then revert changes

  if not git_last_pushed_commit_hash is None:
    git_fetch_head_commit_hash = get_git_fetch_head_commit_hash(git_remote_refspec_token)

    if not git_fetch_head_commit_hash is None:
      is_fetch_head_commit_last_pushed = True if git_last_pushed_commit_hash == git_fetch_head_commit_hash else False
      if not is_fetch_head_commit_last_pushed:
        call_git(['reset'] + (['--hard'] if reset_hard else []) + [git_remote_refspec_token])
        # force reassign the FETCH_HEAD to the last pushed hash
        call_git(['update-ref', git_remote_refspec_token, git_last_pushed_commit_hash])
    else:
      is_fetch_head_commit_last_pushed = False

    # additionally, compare the last pushed commit hash with the head commit hash and if different then revert changes

    git_head_commit_hash = get_git_head_commit_hash(git_local_refspec_token, verify_ref = verify_head_ref)

    if not git_head_commit_hash is None:
      is_head_commit_last_pushed = True if git_last_pushed_commit_hash == git_head_commit_hash else False
      if not is_head_commit_last_pushed:
        call_git(['reset'] + (['--hard'] if reset_hard else []) + [git_local_refspec_token])
        # force reassign the HEAD to the last pushed hash
        call_git(['update-ref', git_local_refspec_token, git_last_pushed_commit_hash])
    else:
      is_head_commit_last_pushed = False

  if not git_last_pushed_commit_hash is None:
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

  with GitShowRefListReader(ret[1]) as git_show_ref_reader:
    for row in git_show_ref_reader:
      ref = row['ref']
      if ref != git_local_refspec_token and ref != git_remote_refspec_token:
        # delete the reference
        call_git(['update-ref', '-d', ref])
        is_ref_list_updated = True
  """

def get_git_svn_subtree_ignore_paths_regex(git_repos_reader, scm_name, remote_name, svn_reporoot):
  parent_svn_reporoot_urlpath = tkl.ParseResult('', *tkl.urlparse(svn_reporoot)[1:]).geturl()

  collected_subtree_svn_path_prefixes = set()

  git_repos_reader.reset()

  # collects only paths with the same repository root

  for subtree_row in git_repos_reader:
    if subtree_row['scm_token'] == scm_name and subtree_row['parent_remote_name'] == remote_name:
      svn_reporoot_urlpath = tkl.ParseResult('', *tkl.urlparse(yaml_expand_global_string(subtree_row['svn_reporoot']))[1:]).geturl()
      if svn_reporoot_urlpath == parent_svn_reporoot_urlpath:
        collected_subtree_svn_path_prefixes.add(yaml_expand_global_string(subtree_row['svn_path_prefix']))

  git_repos_reader.reset()

  # collects the rest paths with different repository roots

  parent_svn_path_prefix = ''
  for subtree_row in git_repos_reader:
    if subtree_row['scm_token'] == scm_name and subtree_row['remote_name'] == remote_name:
      parent_svn_path_prefix = yaml_expand_global_string(subtree_row['svn_path_prefix'])
      break

  git_repos_reader.reset()

  for subtree_row in git_repos_reader:
    if subtree_row['scm_token'] == scm_name and subtree_row['parent_remote_name'] == remote_name:
      collected_subtree_svn_path_prefixes.add(parent_svn_path_prefix + '/' + yaml_expand_global_string(subtree_row['parent_git_path_prefix']))

  # generate `--ignore-paths` string from collected paths

  subtree_git_svn_init_ignore_paths_regex = ''

  for subtree_svn_path_prefix in collected_subtree_svn_path_prefixes:
    subtree_git_svn_path_prefix_regex = get_git_svn_path_prefix_regex(subtree_svn_path_prefix)
    subtree_git_svn_init_ignore_paths_regex += ('|' if len(subtree_git_svn_init_ignore_paths_regex) > 0 else '') + subtree_git_svn_path_prefix_regex

  return subtree_git_svn_init_ignore_paths_regex

"""
def git_svn_fetch_to_last_git_pushed_svn_rev(remote_name, git_local_branch, git_remote_branch, svn_reporoot, svn_path_prefix, git_svn_fetch_cmdline_list = []):
  # search for the last pushed svn revision

  git_last_svn_rev, git_commit_hash, git_commit_timestamp, git_commit_date_time, git_from_commit_timestamp, num_git_commits = \
    get_last_git_svn_rev_by_git_log(remote_name, git_local_branch, git_remote_branch, svn_reporoot, svn_path_prefix)

  # CAUTION:
  #   1. Is required to avoid a fetch into the `master` branch by default.
  #
  call_git(['switch', git_local_branch])

  # direct use of the config section name `svn`
  call_git(['svn', 'fetch', 'svn', '-r' + str(git_last_svn_rev)] + git_svn_fetch_cmdline_list)

  return git_last_svn_rev
"""

# returns as tuple:
#   git_last_svn_rev          - last pushed svn revision if has any
#   git_commit_hash           - git commit associated with the last pushed svn revision if has any, otherwise the last git commit
#   git_commit_timestamp      - git commit timestamp of the `git_commit_hash` commit
#   git_from_commit_timestamp - from there the last search is occured, if None - from FETCH_HEAD, if not None, then has used as: `git log ... FETCH_HEAD ... --until <git_from_commit_timestamp>`
#   num_git_commits           - number of looked up commits from the either FETCH_HEAD or from the `git_from_commit_timestamp` argument in the last `git log` command
#
def get_last_git_svn_rev_by_git_log(remote_name, git_local_branch, git_remote_branch, svn_reporoot, svn_path_prefix, git_log_start_depth = 16):
  # get last pushed svn revision from the `git log` using last commit hash from the git remote repo
  git_last_svn_rev = 0
  git_commit_hash = None
  git_commit_timestamp = None
  git_commit_date_time = None
  num_git_commits = None

  git_log_prev_depth = -1
  git_log_next_depth = git_log_start_depth  # initial `git log` commits depth
  git_log_prev_num_commits = -1
  git_log_next_num_commits = 0

  # use `--until` argument to shift commits window
  git_from_commit_timestamp = None

  # 1. iterate to increase the `git log` depth (`--max-count`) in case of equal the first and the last commit timestamps
  # 2. iterate to shift the `git log` window using `--until` parameter
  while True:
    ret = call_git(['log', '--max-count=' + str(git_log_next_depth), '--format=commit: %H%ntimestamp: %ct%ndate_time: %ci%nauthor: %an <%ae>%n%b',
      get_git_remote_refspec_token(remote_name, git_local_branch, git_remote_branch)] +
      (['--until', str(git_from_commit_timestamp)] if not git_from_commit_timestamp is None else []))

    git_last_svn_rev, git_commit_hash, git_commit_timestamp, git_commit_date_time, num_git_commits = \
      get_git_commit_from_git_log(ret[1], svn_reporoot, svn_path_prefix)

    # quit if the svn revision is found
    if git_last_svn_rev > 0:
      break

    git_log_prev_num_commits = git_log_next_num_commits
    git_log_next_num_commits = num_git_commits

    # the `git log` depth can not be any longer increased (the `git log` list end)
    if git_log_next_depth > git_log_prev_depth and git_log_prev_num_commits >= git_log_next_num_commits:
      break

    git_log_prev_depth = git_log_next_depth

    git_first_commit_svn_rev, git_first_commit_hash, git_first_commit_timestamp = get_git_first_commit_from_git_log(ret[1])

    # increase the depth of the `git log` if the last commit timestamp is not less than the first commit timestamp
    if git_commit_timestamp >= git_first_commit_timestamp:
      git_log_next_depth *= 2
      if git_from_commit_timestamp is None:
        git_from_commit_timestamp = git_first_commit_timestamp
    else:
      # update conditions
      git_log_prev_num_commits = -1
      git_from_commit_timestamp = git_commit_timestamp

  return (git_last_svn_rev, git_commit_hash, git_commit_timestamp, git_commit_date_time, git_from_commit_timestamp, num_git_commits)

def git_update_svn_config_refspecs():
  ret = call_git_no_except(['config', 'svn-remote.svn.fetch'])
  if not ret[0]:
    svn_remote_fetch_refspec_token = ret[1].rstrip()
    if len(svn_remote_fetch_refspec_token) > 0:
      svn_remote_fetch_refspec_token = svn_remote_fetch_refspec_token.replace('refs/remotes/origin/trunk', 'refs/remotes/origin/git-svn-trunk')
      call_git(['config', 'svn-remote.svn.fetch', svn_remote_fetch_refspec_token])

  ret = call_git_no_except(['config', 'svn-remote.svn.branches'])
  if not ret[0]:
    svn_remote_branches_refspec_token = ret[1].rstrip()
    if len(svn_remote_branches_refspec_token) > 0:
      svn_remote_branches_refspec_token = svn_remote_branches_refspec_token.replace('refs/remotes/origin/*', 'refs/remotes/origin/git-svn-branches/*')
      call_git(['config', 'svn-remote.svn.branches', svn_remote_branches_refspec_token])

  ret = call_git_no_except(['config', 'svn-remote.svn.tags'])
  if not ret[0]:
    svn_remote_tags_refspec_token = ret[1].rstrip()
    if len(svn_remote_tags_refspec_token) > 0:
      svn_remote_tags_refspec_token = svn_remote_tags_refspec_token.replace('refs/remotes/origin/tags/*', 'refs/remotes/origin/git-svn-tags/*')
      call_git(['config', 'svn-remote.svn.tags', svn_remote_tags_refspec_token])


def git_init(configure_dir, scm_name, subtrees_root = None, root_only = False):
  print("git_init: {0}".format(configure_dir))

  if configure_dir == '':
    print_err("{0}: error: configure directory is not defined.".format(sys.argv[0]))
    return 1

  if configure_dir[-1:] in ['\\', '/']:
    configure_dir = configure_dir[:-1]

  if not os.path.isdir(configure_dir):
    print_err("{0}: error: configure directory does not exist: `{1}`.".format(sys.argv[0], configure_dir))
    return 32

  if not subtrees_root is None and not os.path.isdir(subtrees_root):
    print_err("{0}: error: subtrees_root directory does not exist: `{1}`.".format(sys.argv[0], subtrees_root))
    return 33

  wcroot_dir = getglobalvar(scm_name + '.WCROOT_DIR')
  if wcroot_dir == '': return -254
  if WCROOT_OFFSET == '': return -253

  wcroot_path = os.path.abspath(os.path.join(WCROOT_OFFSET, wcroot_dir)).replace('\\', '/')

  git_user = getglobalvar(scm_name + '.USER')
  git_email = getglobalvar(scm_name + '.EMAIL')

  print(' -> pushd: {0}...'.format(wcroot_path))

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
          if row['scm_token'] == scm_name and row['branch_type'] == 'root':
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

        # generate `--ignore_paths` for subtrees
        git_svn_init_ignore_paths_regex = get_git_svn_subtree_ignore_paths_regex(git_repos_reader, scm_name, root_remote_name, root_svn_reporoot)
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
          root_svn_url_reg = ret[1]
        if not is_git_root_wcroot_exists or ret[0] or root_svn_url_reg != root_svn_url:
          # removing the git svn config section to avoid it's records duplication on reinit
          call_git_no_except(['config', '--remove-section', 'svn-remote.svn'])

          if SVN_SSH_ENABLED:
            root_svn_url_to_init = tkl.make_url(root_svn_url, yaml_expand_global_string('${${SCM_NAME}.SVNSSH.USER}',
              search_by_pred_at_third = lambda var_name: getglobalvar(var_name)))
          else:
            root_svn_url_to_init = root_svn_url

          call_git(['svn', 'init', root_svn_url_to_init] + root_git_svn_init_cmdline_list)

        # update refspec of git-svn branch to avoid an intersection
        git_update_svn_config_refspecs()

        call_git(['config', 'user.name', git_user])
        call_git(['config', 'user.email', git_email])

        # register git remotes
        register_git_remotes(git_repos_reader, scm_name, root_remote_name, True)

        print('---')

        if root_only:
          return

        is_builtin_subtrees_root = False
        if subtrees_root is None:
          subtrees_root = wcroot_path + '/.git/svn2git/gitwc'
          is_builtin_subtrees_root = True

        # Initialize non root git repositories as stanalone working copies inside the `subtrees_root` directory,
        # use the combination of the `remote_name` and the `parent_git_path_prefix` as a prefix to a working copy directory.

        git_repos_reader.reset()

        for subtree_row in git_repos_reader:
          if subtree_row['scm_token'] == scm_name and subtree_row['branch_type'] != 'root':
            subtree_parent_git_path_prefix = subtree_row['parent_git_path_prefix']

            if subtree_parent_git_path_prefix == '.':
              raise Exception('not root branch type must have not empty git parent path prefix')

            subtree_remote_name = subtree_row['remote_name']
            if subtree_remote_name in remote_name_list:
              raise Exception('remote_name must be unique in the repositories list for the same scm_token')

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

            subtree_git_wcroot = os.path.abspath(os.path.join(subtrees_root, subtree_remote_name + "'" + subtree_parent_git_path_prefix.replace('/', '--'))).replace('\\', '/')

            if is_builtin_subtrees_root:
              if not os.path.exists(subtrees_root):
                print('>mkdir: -p ' + subtrees_root)
                try:
                  os.makedirs(subtrees_root)
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
                # generate `--ignore_paths` for subtrees
                subtree_git_svn_init_ignore_paths_regex = get_git_svn_subtree_ignore_paths_regex(subtree_git_repos_reader, scm_name, subtree_remote_name, subtree_svn_reporoot)
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
                  subtree_svn_url_reg = ret[1]
                if not is_git_subtree_wcroot_exists or ret[0] or subtree_svn_url_reg != subtree_svn_url:
                  # removing the git svn config section to avoid it's records duplication on reinit
                  call_git_no_except(['config', '--remove-section', 'svn-remote.svn'])

                  if SVN_SSH_ENABLED:
                    subtree_svn_url_to_init = tkl.make_url(subtree_svn_url, yaml_expand_global_string('${${SCM_NAME}.SVNSSH.USER}',
                      search_by_pred_at_third = lambda var_name: getglobalvar(var_name)))
                  else:
                    subtree_svn_url_to_init = subtree_svn_url

                  call_git(['svn', 'init', subtree_svn_url_to_init] + subtree_git_svn_init_cmdline_list)

                # update refspec of git-svn branch to avoid an intersection
                git_update_svn_config_refspecs()

                call_git(['config', 'user.name', git_user])
                call_git(['config', 'user.email', git_email])

                # register git remotes
                register_git_remotes(subtree_git_repos_reader, scm_name, subtree_remote_name, True)

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

def read_git_svn_repo_list(git_repos_reader, scm_name, wcroot_path, subtrees_root, column_names, column_widths):
  print('- Reading GIT-SVN repositories list:')

  has_root = False

  git_repos_reader.reset()

  for row in git_repos_reader:
    if row['scm_token'] == scm_name and row['branch_type'] == 'root':
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

  if subtrees_root is None:
    subtrees_root = wcroot_path + '/.git/svn2git/gitwc'

  root_svn_repopath = root_svn_reporoot + ('/' + root_svn_path_prefix if root_svn_path_prefix != '' else '')

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
  #     'last_pushed_git_svn_commit'                      : [
  #       (<svn_rev>, <git_hash>, <svn_timestamp>, <svn_date_time>), ...
  #     ],
  #     'unpushed_svn_commit_list'                        : [
  #       (<svn_rev>, <svn_user_name>, <svn_timestamp>, <svn_date_time>), ...
  #     ]
  #   }
  #
  git_svn_repo_tree = {
    root_remote_name : (
      {
        'nest_index'                    : 0,                  # the root
        'parent_tuple_ref'              : None,
        'remote_name'                   : root_remote_name,
        'parent_remote_name'            : '.',                # special case: if parent remote name is the '.', then it is the root
        'git_reporoot'                  : root_git_reporoot,
        'parent_git_path_prefix'        : root_parent_git_path_prefix,
        'svn_reporoot'                  : root_svn_reporoot,
        'svn_repo_uuid'                 : '',                 # to avoid complex compare
        'svn_path_prefix'               : root_svn_path_prefix,
        'git_local_branch'              : root_git_local_branch,
        'git_remote_branch'             : root_git_remote_branch,
        'git_wcroot'                    : '.'
      },
      # must be assigned at once, otherwise: `TypeError: 'tuple' object does not support item assignment`
      {},
      {}
    )
  }

  git_svn_repo_tree_tuple_ref_preorder_list = [ git_svn_repo_tree[root_remote_name] ]

  # Format: [ <ref_to_repo_tree_tuple>, ... ]
  #
  parent_child_remote_names_to_parse = [ git_svn_repo_tree[root_remote_name] ]

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
      if subtree_row['scm_token'] == scm_name and subtree_row['branch_type'] != 'root':
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

          subtree_svn_repopath = subtree_svn_reporoot + ('/' + subtree_svn_path_prefix if subtree_svn_path_prefix != '' else '')

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
                  os.path.join(subtrees_root, subtree_remote_name + "'" + subtree_parent_git_path_prefix.replace('/', '--'))
                ).replace('\\', '/')
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

  print('- Updating SVN repositories info...')

  svn_repo_root_to_uuid_dict = {}

  for git_svn_repo_tree_tuple_ref in git_svn_repo_tree_tuple_ref_preorder_list:
    repo_params_ref = git_svn_repo_tree_tuple_ref[0]

    svn_reporoot = repo_params_ref['svn_reporoot']

    if svn_reporoot not in svn_repo_root_to_uuid_dict.keys():
      ret = call_svn(['info', '--show-item', 'repos-uuid', svn_reporoot])

      svn_repo_uuid = ret[1]
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

  return (git_svn_repo_tree, git_svn_repo_tree_tuple_ref_preorder_list)

def get_git_svn_repos_list_table_params():
  return (
    ['<remote_name>', '<git_reporoot>', '<parent_git_prefix>', '<svn_repopath>', '<git_local_branch>', '<git_remote_branch>'],
    [20, 64, 20, 64, 20, 20]
  )

def get_max_time_depth_in_multiple_svn_commits_fetch_sec():
  # maximal time depth in a multiple svn commits fetch from an svn repository
  return 2678400 # seconds in 1 month (31 days)

def get_min_tree_time_of_last_unpushed_svn_commit(git_svn_repo_tree_tuple_ref_preorder_list):
  git_svn_repo_tree_tuple_root_ref = git_svn_repo_tree_tuple_ref_preorder_list[0]
  repo_params_root_ref = git_svn_repo_tree_tuple_root_ref[0]
  if not repo_params_root_ref['parent_tuple_ref'] is None:
    raise Exception('first element in git_svn_repo_tree_tuple_ref_preorder_list is not a tree root')
  fetch_state_root_ref = git_svn_repo_tree_tuple_root_ref[1]
  min_tree_time_of_last_unpushed_svn_commit = fetch_state_root_ref['min_tree_time_of_last_unpushed_svn_commit']
  return min_tree_time_of_last_unpushed_svn_commit

def print_min_tree_time_of_last_unpushed_svn_commit(prefix_str, git_svn_repo_tree_tuple_ref_preorder_list):
  min_tree_time_of_last_unpushed_svn_commit = get_min_tree_time_of_last_unpushed_svn_commit(git_svn_repo_tree_tuple_ref_preorder_list)
  print(prefix_str + 'min_tree_time_of_last_unpushed_svn_commit = ' + str(min_tree_time_of_last_unpushed_svn_commit[0]) +
    ' {' + min_tree_time_of_last_unpushed_svn_commit[1] + '}')

def get_min_ro_tree_time_of_first_unpushed_svn_commit(git_svn_repo_tree_tuple_ref):
  fetch_state_ref = git_svn_repo_tree_tuple_ref[1]
  min_ro_tree_time_of_first_unpushed_svn_commit = fetch_state_ref['min_ro_tree_time_of_first_unpushed_svn_commit']
  return min_ro_tree_time_of_first_unpushed_svn_commit

def update_git_svn_repo_fetch_state(git_svn_repo_tree_tuple_ref_preorder_list, max_time_depth_in_multiple_svn_commits_fetch_sec, root_only = False, first_time_update = True):
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

      svn_repopath = svn_reporoot + ('/' + svn_path_prefix if svn_path_prefix != '' else '')

      with conditional(git_wcroot != '.', local.cwd(git_wcroot)):
        git_remote_refspec_token, git_remote_local_refspec_token = \
          get_git_remote_refspec_token_tuple(remote_name, git_local_branch, git_remote_branch)

        # get last pushed commit hash
        git_last_pushed_commit_hash = get_git_last_pushed_commit_hash(git_reporoot, git_remote_local_refspec_token)

        git_last_svn_rev = 0

        if not git_last_pushed_commit_hash is None:
          # get last git-svn revision w/o fetch because it must be already fetched

          if first_time_pass:
            git_last_svn_rev, git_commit_hash, git_commit_timestamp, git_commit_date_time, git_from_commit_timestamp, num_git_commits = \
              get_last_git_svn_rev_by_git_log(remote_name, git_local_branch, git_remote_branch, svn_reporoot, svn_path_prefix)
          else:
            # read the saved fetch state
            last_pushed_git_svn_commit = fetch_state_ref['last_pushed_git_svn_commit']
            git_last_svn_rev, git_commit_hash, svn_commit_timestamp, svn_commit_date_time = last_pushed_git_svn_commit

          if not git_last_svn_rev >= 0:
            raise Exception('invalid git_last_svn_rev value: `' + str(git_last_svn_rev) + '`')

        if git_last_svn_rev > 0:
          if first_time_pass:
            # request svn_commit_timestamp and svn_commit_date_time from svn by git_last_svn_rev
            target_svn_commit_list = get_svn_commit_list(svn_repopath, 1, git_last_svn_rev)

            # update to actual svn commit timestamp and date time
            target_svn_commit = target_svn_commit_list[0]

            target_svn_commit_rev = target_svn_commit[0]
            if target_svn_commit_rev != git_last_svn_rev:
              raise Exception('svn log returned invalid svn revision: requested=' + git_last_svn_rev + '; returned=' + target_svn_commit_rev)

            svn_commit_timestamp = target_svn_commit[2]
            svn_commit_date_time = target_svn_commit[3]
        else:
          # nothing found
          git_commit_hash = None
          git_commit_timestamp = None
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

          svn_last_changed_rev = ret[1]
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
          git_commit_date_time
        )
        fetch_state_ref['unpushed_svn_commit_list'] = unpushed_svn_commit_list

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

  print_min_tree_time_of_last_unpushed_svn_commit('  * - ', git_svn_repo_tree_tuple_ref_preorder_list)

  if is_first_unpushed_svn_commit_invalid:
    raise Exception('one or more git-svn repositories contains a not pushed svn revision less or equal to the last pushed one')

  return True

def git_fetch(configure_dir, scm_name, subtrees_root = None, root_only = False, reset_hard = False):
  print("git_fetch: {0}".format(configure_dir))

  if not subtrees_root is None:
    print(' * subtrees_root: `' + subtrees_root + '`')

  if configure_dir == '':
    print_err("{0}: error: configure directory is not defined.".format(sys.argv[0]))
    return 1

  if configure_dir[-1:] in ['\\', '/']:
    configure_dir = configure_dir[:-1]

  if not os.path.isdir(configure_dir):
    print_err("{0}: error: configure directory does not exist: `{1}`.".format(sys.argv[0], configure_dir))
    return 32

  if not subtrees_root is None and not os.path.isdir(subtrees_root):
    print_err("{0}: error: subtrees_root directory does not exist: `{1}`.".format(sys.argv[0], subtrees_root))
    return 33

  wcroot_dir = getglobalvar(scm_name + '.WCROOT_DIR')
  if wcroot_dir == '': return -254
  if WCROOT_OFFSET == '': return -253

  wcroot_path = os.path.abspath(os.path.join(WCROOT_OFFSET, wcroot_dir)).replace('\\', '/')

  git_user = getglobalvar(scm_name + '.USER')
  git_email = getglobalvar(scm_name + '.EMAIL')

  print(' -> pushd: {0}...'.format(wcroot_path))

  if not os.path.exists(wcroot_path):
    os.mkdir(wcroot_path)

  max_time_depth_in_multiple_svn_commits_fetch_sec = get_max_time_depth_in_multiple_svn_commits_fetch_sec()

  with local.cwd(wcroot_path), GitReposListReader(configure_dir + '/git_repos.lst') as git_repos_reader, ServiceProcCache() as svc_proc_cache:
    executed_procs = cache_init_service_proc(svc_proc_cache)

    with tkl.OnExit(lambda: cache_close_running_procs(executed_procs, svc_proc_cache)):
      column_names, column_widths = get_git_svn_repos_list_table_params()

      if subtrees_root is None:
        subtrees_root = wcroot_path + '/.git/svn2git/gitwc'

      git_svn_repo_tree, git_svn_repo_tree_tuple_ref_preorder_list = \
        read_git_svn_repo_list(git_repos_reader, scm_name, wcroot_path, subtrees_root, column_names, column_widths)

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
          subtree_git_wcroot = os.path.abspath(os.path.join(subtrees_root, remote_name + "'" + parent_git_path_prefix.replace('/', '--'))).replace('\\', '/')

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

          revert_if_git_head_refs_is_not_last_pushed(git_last_pushed_commit_hash, git_local_refspec_token, git_remote_refspec_token,
            reset_hard = True)

          print('---')

          if parent_tuple_ref is None and root_only:
            break

      update_git_svn_repo_fetch_state(git_svn_repo_tree_tuple_ref_preorder_list, max_time_depth_in_multiple_svn_commits_fetch_sec, root_only = root_only)

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

        if not parent_tuple_ref is None:
          subtree_git_wcroot = os.path.abspath(os.path.join(subtrees_root, remote_name + "'" + parent_git_path_prefix.replace('/', '--'))).replace('\\', '/')

          print(' ->> cwd: `{0}`...'.format(subtree_git_wcroot))
        else:
          print(' ->> cwd: `{0}`...'.format(wcroot_path))

        with conditional(not parent_tuple_ref is None, local.cwd(subtree_git_wcroot) if not parent_tuple_ref is None else None):
          # generate `--ignore_paths` for subtrees

          git_svn_fetch_cmdline_list = []

          git_svn_fetch_ignore_paths_regex = get_git_svn_subtree_ignore_paths_regex(git_repos_reader, scm_name, remote_name, svn_reporoot)
          if len(git_svn_fetch_ignore_paths_regex) > 0:
            git_svn_fetch_cmdline_list.append('--ignore-paths=' + git_svn_fetch_ignore_paths_regex)

          # git-svn (re)fetch next svn revision

          git_remote_refspec_token, git_remote_local_refspec_token = \
            get_git_remote_refspec_token_tuple(remote_name, git_local_branch, git_remote_branch)

          # get last pushed commit hash
          git_last_pushed_commit_hash = get_git_last_pushed_commit_hash(git_reporoot, git_remote_local_refspec_token)

          if not git_last_pushed_commit_hash is None:
            # CAUTION:
            #   1. Is required to avoid a fetch into the `master` branch by default.
            #
            call_git(['switch', git_local_branch])

          # CAUTION:
          #   1. We can not rollback the svn remote branch to a particular revision through the `git svn reset -r <rev>` because
          #      the branch can be w/o a common ancestor which is a requirement to success accomplish.
          #      Instead of drop revisions in a branch do remove entire branch and the index, so the next fetch command would
          #      retake the target revision again.
          #
          git_remove_svn_branch('origin/git-svn-trunk', 'refs/remotes/origin/git-svn-trunk')

          # direct use of the config section name `svn`
          last_pushed_git_svn_commit = fetch_state_ref['last_pushed_git_svn_commit']
          last_pushed_git_svn_commit_rev = last_pushed_git_svn_commit[0]

          call_git(['svn', 'fetch', 'svn', '-r' + str(last_pushed_git_svn_commit_rev)] + git_svn_fetch_cmdline_list,
            ignore_warnings = False if last_pushed_git_svn_commit_rev > 0 else True)

          # revert again if last fetch has broke the HEAD

          git_local_refspec_token = get_git_local_refspec_token(git_local_branch, git_remote_branch)

          revert_if_git_head_refs_is_not_last_pushed(git_last_pushed_commit_hash, git_local_refspec_token, git_remote_refspec_token,
            reset_hard = True)

          # get fetch subtrees
          git_fetch_subtrees(git_repos_reader, scm_name, remote_name)

          """
          if not parent_tuple_ref is None:
            with open('.git/HEAD', 'wt') as head_file:
              head_file.write('ref: ' + git_local_refspec_token)
              head_file.close()
          """

          print('---')

          if parent_tuple_ref is None and root_only:
            break

def git_reset(configure_dir, scm_name, subtrees_root = None, root_only = False, reset_hard = False):
  print("git_reset: {0}".format(configure_dir))

  if not subtrees_root is None:
    print(' * subtrees_root: `' + subtrees_root + '`')

  if configure_dir == '':
    print_err("{0}: error: configure directory is not defined.".format(sys.argv[0]))
    return 1

  if configure_dir[-1:] in ['\\', '/']:
    configure_dir = configure_dir[:-1]

  if not os.path.isdir(configure_dir):
    print_err("{0}: error: configure directory does not exist: `{1}`.".format(sys.argv[0], configure_dir))
    return 32

  if not subtrees_root is None and not os.path.isdir(subtrees_root):
    print_err("{0}: error: subtrees_root directory does not exist: `{1}`.".format(sys.argv[0], subtrees_root))
    return 33

  wcroot_dir = getglobalvar(scm_name + '.WCROOT_DIR')
  if wcroot_dir == '': return -254
  if WCROOT_OFFSET == '': return -253

  wcroot_path = os.path.abspath(os.path.join(WCROOT_OFFSET, wcroot_dir)).replace('\\', '/')

  git_user = getglobalvar(scm_name + '.USER')
  git_email = getglobalvar(scm_name + '.EMAIL')

  print(' -> pushd: {0}...'.format(wcroot_path))

  if not os.path.exists(wcroot_path):
    os.mkdir(wcroot_path)

  with local.cwd(wcroot_path), GitReposListReader(configure_dir + '/git_repos.lst') as git_repos_reader, ServiceProcCache() as svc_proc_cache:
    executed_procs = cache_init_service_proc(svc_proc_cache)

    with tkl.OnExit(lambda: cache_close_running_procs(executed_procs, svc_proc_cache)):
      column_names, column_widths = get_git_svn_repos_list_table_params()

      if subtrees_root is None:
        subtrees_root = wcroot_path + '/.git/svn2git/gitwc'

      git_svn_repo_tree, git_svn_repo_tree_tuple_ref_preorder_list = \
        read_git_svn_repo_list(git_repos_reader, scm_name, wcroot_path, subtrees_root, column_names, column_widths)

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
          subtree_git_wcroot = os.path.abspath(os.path.join(subtrees_root, remote_name + "'" + parent_git_path_prefix.replace('/', '--'))).replace('\\', '/')

          print(' ->> cwd: `{0}`...'.format(subtree_git_wcroot))
        else:
          print(' ->> cwd: `{0}`...'.format(wcroot_path))

        with conditional(not parent_tuple_ref is None, local.cwd(subtree_git_wcroot) if not parent_tuple_ref is None else None):
          git_remote_refspec_token, git_remote_local_refspec_token = \
            get_git_remote_refspec_token_tuple(remote_name, git_local_branch, git_remote_branch)

          # get last pushed commit hash
          git_last_pushed_commit_hash = get_git_last_pushed_commit_hash(git_reporoot, git_remote_local_refspec_token)

          if not git_last_pushed_commit_hash is None:
            call_git(['switch', git_local_branch])

          print('---')

          if parent_tuple_ref is None and root_only:
            break

      print('- GIT resetting...')

      for git_svn_repo_tree_tuple_ref in git_svn_repo_tree_tuple_ref_preorder_list:
        repo_params_ref = git_svn_repo_tree_tuple_ref[0]

        parent_tuple_ref = repo_params_ref['parent_tuple_ref']

        remote_name = repo_params_ref['remote_name']

        git_reporoot = repo_params_ref['git_reporoot']

        parent_git_path_prefix = repo_params_ref['parent_git_path_prefix']

        git_local_branch = repo_params_ref['git_local_branch']
        git_remote_branch = repo_params_ref['git_remote_branch']

        if not parent_tuple_ref is None:
          subtree_git_wcroot = os.path.abspath(os.path.join(subtrees_root, remote_name + "'" + parent_git_path_prefix.replace('/', '--'))).replace('\\', '/')

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

          revert_if_git_head_refs_is_not_last_pushed(git_last_pushed_commit_hash, git_local_refspec_token, git_remote_refspec_token,
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

      print('- GIT-SVN resetting...')

      for git_svn_repo_tree_tuple_ref in git_svn_repo_tree_tuple_ref_preorder_list:
        repo_params_ref = git_svn_repo_tree_tuple_ref[0]

        parent_tuple_ref = repo_params_ref['parent_tuple_ref']

        remote_name = repo_params_ref['remote_name']

        parent_git_path_prefix = repo_params_ref['parent_git_path_prefix']

        if not parent_tuple_ref is None:
          subtree_git_wcroot = os.path.abspath(os.path.join(subtrees_root, remote_name + "'" + parent_git_path_prefix.replace('/', '--'))).replace('\\', '/')

          print(' ->> cwd: `{0}`...'.format(subtree_git_wcroot))
        else:
          print(' ->> cwd: `{0}`...'.format(wcroot_path))

        with conditional(not parent_tuple_ref is None, local.cwd(subtree_git_wcroot) if not parent_tuple_ref is None else None):
          git_remove_subtree_branches(git_repos_reader, scm_name, remote_name)

          git_remove_svn_branch('origin/git-svn-trunk', 'refs/remotes/origin/git-svn-trunk')

          print('---')

          if parent_tuple_ref is None and root_only:
            break

def git_pull(configure_dir, scm_name, subtrees_root = None, root_only = False, reset_hard = False):
  print("git_pull: {0}".format(configure_dir))

  if not subtrees_root is None:
    print(' * subtrees_root: `' + subtrees_root + '`')

  if configure_dir == '':
    print_err("{0}: error: configure directory is not defined.".format(sys.argv[0]))
    return 1

  if configure_dir[-1:] in ['\\', '/']:
    configure_dir = configure_dir[:-1]

  if not os.path.isdir(configure_dir):
    print_err("{0}: error: configure directory does not exist: `{1}`.".format(sys.argv[0], configure_dir))
    return 32

  if not subtrees_root is None and not os.path.isdir(subtrees_root):
    print_err("{0}: error: subtrees_root directory does not exist: `{1}`.".format(sys.argv[0], subtrees_root))
    return 33

  wcroot_dir = getglobalvar(scm_name + '.WCROOT_DIR')
  if wcroot_dir == '': return -254
  if WCROOT_OFFSET == '': return -253

  wcroot_path = os.path.abspath(os.path.join(WCROOT_OFFSET, wcroot_dir)).replace('\\', '/')

  git_user = getglobalvar(scm_name + '.USER')
  git_email = getglobalvar(scm_name + '.EMAIL')

  print(' -> pushd: {0}...'.format(wcroot_path))

  if not os.path.exists(wcroot_path):
    os.mkdir(wcroot_path)

  max_time_depth_in_multiple_svn_commits_fetch_sec = get_max_time_depth_in_multiple_svn_commits_fetch_sec()

  with local.cwd(wcroot_path), GitReposListReader(configure_dir + '/git_repos.lst') as git_repos_reader, ServiceProcCache() as svc_proc_cache:
    executed_procs = cache_init_service_proc(svc_proc_cache)

    with tkl.OnExit(lambda: cache_close_running_procs(executed_procs, svc_proc_cache)):
      column_names, column_widths = get_git_svn_repos_list_table_params()

      if subtrees_root is None:
        subtrees_root = wcroot_path + '/.git/svn2git/gitwc'

      git_svn_repo_tree, git_svn_repo_tree_tuple_ref_preorder_list = \
        read_git_svn_repo_list(git_repos_reader, scm_name, wcroot_path, subtrees_root, column_names, column_widths)

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
          subtree_git_wcroot = os.path.abspath(os.path.join(subtrees_root, remote_name + "'" + parent_git_path_prefix.replace('/', '--'))).replace('\\', '/')

          print(' ->> cwd: `{0}`...'.format(subtree_git_wcroot))
        else:
          print(' ->> cwd: `{0}`...'.format(wcroot_path))

        with conditional(not parent_tuple_ref is None, local.cwd(subtree_git_wcroot) if not parent_tuple_ref is None else None):
          git_remote_refspec_token, git_remote_local_refspec_token = \
            get_git_remote_refspec_token_tuple(remote_name, git_local_branch, git_remote_branch)

          # get last pushed commit hash
          git_last_pushed_commit_hash = get_git_last_pushed_commit_hash(git_reporoot, git_remote_local_refspec_token)

          if not git_last_pushed_commit_hash is None:
            call_git(['switch', git_local_branch])

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
          subtree_git_wcroot = os.path.abspath(os.path.join(subtrees_root, remote_name + "'" + parent_git_path_prefix.replace('/', '--'))).replace('\\', '/')

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

          revert_if_git_head_refs_is_not_last_pushed(git_last_pushed_commit_hash, git_local_refspec_token, git_remote_refspec_token,
            reset_hard = reset_hard)

          print('---')

          if parent_tuple_ref is None and root_only:
            break

      update_git_svn_repo_fetch_state(git_svn_repo_tree_tuple_ref_preorder_list, max_time_depth_in_multiple_svn_commits_fetch_sec, root_only = root_only)

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

        if not parent_tuple_ref is None:
          subtree_git_wcroot = os.path.abspath(os.path.join(subtrees_root, remote_name + "'" + parent_git_path_prefix.replace('/', '--'))).replace('\\', '/')

          print(' ->> cwd: `{0}`...'.format(subtree_git_wcroot))
        else:
          print(' ->> cwd: `{0}`...'.format(wcroot_path))

        with conditional(not parent_tuple_ref is None, local.cwd(subtree_git_wcroot) if not parent_tuple_ref is None else None):
          # generate `--ignore_paths` for subtrees

          git_svn_fetch_cmdline_list = []

          git_svn_fetch_ignore_paths_regex = get_git_svn_subtree_ignore_paths_regex(git_repos_reader, scm_name, remote_name, svn_reporoot)
          if len(git_svn_fetch_ignore_paths_regex) > 0:
            git_svn_fetch_cmdline_list.append('--ignore-paths=' + git_svn_fetch_ignore_paths_regex)

          # git-svn (re)fetch next svn revision

          git_remote_refspec_token, git_remote_local_refspec_token = \
            get_git_remote_refspec_token_tuple(remote_name, git_local_branch, git_remote_branch)

          # get last pushed commit hash
          git_last_pushed_commit_hash = get_git_last_pushed_commit_hash(git_reporoot, git_remote_local_refspec_token)

          if not git_last_pushed_commit_hash is None:
            # CAUTION:
            #   1. Is required to avoid a fetch into the `master` branch by default.
            #
            call_git(['switch', git_local_branch])

          # CAUTION:
          #   1. We can not rollback the svn remote branch to a particular revision through the `git svn reset -r <rev>` because
          #      the branch can be w/o a common ancestor which is a requirement to success accomplish.
          #      Instead of drop revisions in a branch do remove entire branch and the index, so the next fetch command would
          #      retake the target revision again.
          #
          git_remove_svn_branch('origin/git-svn-trunk', 'refs/remotes/origin/git-svn-trunk')

          # direct use of the config section name `svn`
          last_pushed_git_svn_commit = fetch_state_ref['last_pushed_git_svn_commit']
          last_pushed_git_svn_commit_rev = last_pushed_git_svn_commit[0]
          call_git(['svn', 'fetch', 'svn', '-r' + str(last_pushed_git_svn_commit_rev)] + git_svn_fetch_cmdline_list,
            ignore_warnings = False if last_pushed_git_svn_commit_rev > 0 else True)

          # revert again if last fetch has broke the HEAD

          git_local_refspec_token = get_git_local_refspec_token(git_local_branch, git_remote_branch)

          revert_if_git_head_refs_is_not_last_pushed(git_last_pushed_commit_hash, git_local_refspec_token, git_remote_refspec_token,
            reset_hard = reset_hard)

          """
          if not parent_tuple_ref is None:
            with open('.git/HEAD', 'wt') as head_file:
              head_file.write('ref: ' + git_local_refspec_token)
              head_file.close()
          """

          # get fetch subtrees
          git_fetch_subtrees(git_repos_reader, scm_name, remote_name)

          print('---')

          if parent_tuple_ref is None and root_only:
            break

      print('- GIT switching...')

      for git_svn_repo_tree_tuple_ref in git_svn_repo_tree_tuple_ref_preorder_list:
        repo_params_ref = git_svn_repo_tree_tuple_ref[0]

        parent_tuple_ref = repo_params_ref['parent_tuple_ref']

        remote_name = repo_params_ref['remote_name']

        parent_git_path_prefix = repo_params_ref['parent_git_path_prefix']

        git_local_branch = repo_params_ref['git_local_branch']

        if not parent_tuple_ref is None:
          subtree_git_wcroot = os.path.abspath(os.path.join(subtrees_root, remote_name + "'" + parent_git_path_prefix.replace('/', '--'))).replace('\\', '/')

          print(' ->> cwd: `{0}`...'.format(subtree_git_wcroot))
        else:
          print(' ->> cwd: `{0}`...'.format(wcroot_path))

        with conditional(not parent_tuple_ref is None, local.cwd(subtree_git_wcroot) if not parent_tuple_ref is None else None):
          call_git(['switch', git_local_branch])

          print('---')

          if parent_tuple_ref is None and root_only:
            break

def collect_unpushed_svn_revisions_ordered_by_timestamp(git_svn_repo_tree_tuple_ref_preorder_list):
  print('- Collecting unpushed svn commits:')

  unpushed_svn_commit_by_timestamp_dict = {}

  for git_svn_repo_tree_tuple_ref in reversed(git_svn_repo_tree_tuple_ref_preorder_list): # in reverse
    fetch_state_ref = git_svn_repo_tree_tuple_ref[1]

    is_read_only_repo = fetch_state_ref['is_read_only_repo']
    if is_read_only_repo:
      # can not puth into a read only git repository
      continue

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

  min_tree_time_of_last_unpushed_svn_commit = get_min_tree_time_of_last_unpushed_svn_commit(git_svn_repo_tree_tuple_ref_preorder_list)
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

      nest_index = repo_params_ref['nest_index']
      remote_name = repo_params_ref['remote_name']
      svn_reporoot = repo_params_ref['svn_reporoot']
      svn_path_prefix = repo_params_ref['svn_path_prefix']

      svn_repopath = svn_reporoot + ('/' + svn_path_prefix if svn_path_prefix != '' else '')

      row_values = [('* ' if unpushed_svn_commit_timestamp == min_tree_time_of_last_unpushed_svn_commit_timestamp else '  ') + \
        str(unpushed_svn_commit_timestamp) + ' {' + unpushed_svn_commit_tuple[1] + '}',
        'r' + str(unpushed_svn_commit_tuple[0]), ('| ' * nest_index) + remote_name, svn_repopath]
      git_print_repos_list_row(row_values, column_widths, column_fmt_str)

  git_print_repos_list_footer(column_widths)

  print_min_tree_time_of_last_unpushed_svn_commit('  * - ', git_svn_repo_tree_tuple_ref_preorder_list)

  return unpushed_svn_commit_by_timestamp_dict

# CAUTION:
#   * The function always does process the root repository together along with the subtree repositories, because
#     it is a part of a whole 1-way synchronization process between the SVN and the GIT.
#     If you want to reduce the depth or change the configuration of subtrees, you have to edit the respective
#     `git_repos.lst` file.
#     If you want to process subtree repositories by a custom (not builtin) path,
#     then do use the `subtrees_root` argument as a root path to the subtree directories.
#
def git_push_from_svn(configure_dir, scm_name, subtrees_root = None, reset_hard = False):
  print(">git_push_from_svn: {0}".format(configure_dir))

  if not subtrees_root is None:
    print(' * subtrees_root: `' + subtrees_root + '`')

  if configure_dir == '':
    print_err("{0}: error: configure directory is not defined.".format(sys.argv[0]))
    return 1

  if configure_dir[-1:] in ['\\', '/']:
    configure_dir = configure_dir[:-1]

  if not os.path.isdir(configure_dir):
    print_err("{0}: error: configure directory does not exist: `{1}`.".format(sys.argv[0], configure_dir))
    return 32

  if not subtrees_root is None and not os.path.isdir(subtrees_root):
    print_err("{0}: error: subtrees_root directory does not exist: `{1}`.".format(sys.argv[0], subtrees_root))
    return 33

  wcroot_dir = getglobalvar(scm_name + '.WCROOT_DIR')
  if wcroot_dir == '': return -254
  if WCROOT_OFFSET == '': return -253

  wcroot_path = os.path.abspath(os.path.join(WCROOT_OFFSET, wcroot_dir)).replace('\\', '/')

  git_user = getglobalvar(scm_name + '.USER')
  git_email = getglobalvar(scm_name + '.EMAIL')

  print(' -> pushd: {0}...'.format(wcroot_path))

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

      if subtrees_root is None:
        subtrees_root = wcroot_path + '/.git/svn2git/gitwc'

      git_svn_repo_tree, git_svn_repo_tree_tuple_ref_preorder_list = \
        read_git_svn_repo_list(git_repos_reader, scm_name, wcroot_path, subtrees_root, column_names, column_widths)

      print('- GIT switching...')

      for git_svn_repo_tree_tuple_ref in git_svn_repo_tree_tuple_ref_preorder_list:
        repo_params_ref = git_svn_repo_tree_tuple_ref[0]

        parent_tuple_ref = repo_params_ref['parent_tuple_ref']

        remote_name = repo_params_ref['remote_name']

        parent_git_path_prefix = repo_params_ref['parent_git_path_prefix']

        git_local_branch = repo_params_ref['git_local_branch']
        git_remote_branch = repo_params_ref['git_remote_branch']

        if not parent_tuple_ref is None:
          subtree_git_wcroot = os.path.abspath(os.path.join(subtrees_root, remote_name + "'" + parent_git_path_prefix.replace('/', '--'))).replace('\\', '/')

          print(' ->> cwd: `{0}`...'.format(subtree_git_wcroot))
        else:
          print(' ->> cwd: `{0}`...'.format(wcroot_path))

        with conditional(not parent_tuple_ref is None, local.cwd(subtree_git_wcroot) if not parent_tuple_ref is None else None):
          git_local_refspec_token = get_git_local_refspec_token(git_local_branch, git_remote_branch)
          git_remote_refspec_token = get_git_remote_refspec_token(remote_name, git_local_branch, git_remote_branch)

          ret = call_git_no_except(['show-ref', '--verify', git_local_refspec_token])

          # CAUTION:
          #   1. Is required to avoid a fetch into the `master` branch by default.
          #
          if not ret[0]:
            call_git(['switch', git_local_branch])
          else:
            call_git(['switch', '-c', git_local_branch])

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
          subtree_git_wcroot = os.path.abspath(os.path.join(subtrees_root, remote_name + "'" + parent_git_path_prefix.replace('/', '--'))).replace('\\', '/')

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

          revert_if_git_head_refs_is_not_last_pushed(git_last_pushed_commit_hash, git_local_refspec_token, git_remote_refspec_token,
            reset_hard = True)

          print('---')

      # 1. + 2.
      #

      has_unpushed_svn_revisions_to_update = \
        update_git_svn_repo_fetch_state(git_svn_repo_tree_tuple_ref_preorder_list, max_time_depth_in_multiple_svn_commits_fetch_sec)
      if not has_unpushed_svn_revisions_to_update:
        return

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

        if not parent_tuple_ref is None:
          subtree_git_wcroot = os.path.abspath(os.path.join(subtrees_root, remote_name + "'" + parent_git_path_prefix.replace('/', '--'))).replace('\\', '/')

          print(' ->> cwd: `{0}`...'.format(subtree_git_wcroot))
        else:
          print(' ->> cwd: `{0}`...'.format(wcroot_path))

        with conditional(not parent_tuple_ref is None, local.cwd(subtree_git_wcroot) if not parent_tuple_ref is None else None):
          # generate `--ignore_paths` for subtrees

          git_svn_fetch_cmdline_list = []

          git_svn_fetch_ignore_paths_regex = get_git_svn_subtree_ignore_paths_regex(git_repos_reader, scm_name, remote_name, svn_reporoot)
          if len(git_svn_fetch_ignore_paths_regex) > 0:
            git_svn_fetch_cmdline_list.append('--ignore-paths=' + git_svn_fetch_ignore_paths_regex)

          # git-svn (re)fetch next svn revision

          # CAUTION:
          #   1. We can not rollback the svn remote branch to a particular revision through the `git svn reset -r <rev>` because
          #      the branch can be w/o a common ancestor which is a requirement to success accomplish.
          #      Instead of drop revisions in a branch do remove entire branch and the index, so the next fetch command would
          #      retake the target revision again.
          #
          git_remove_svn_branch('origin/git-svn-trunk', 'refs/remotes/origin/git-svn-trunk')

          # direct use of the config section name `svn`
          last_pushed_git_svn_commit = fetch_state_ref['last_pushed_git_svn_commit']
          last_pushed_git_svn_commit_rev = last_pushed_git_svn_commit[0]
          call_git(['svn', 'fetch', 'svn', '-r' + str(last_pushed_git_svn_commit_rev)] + git_svn_fetch_cmdline_list,
            ignore_warnings = False if last_pushed_git_svn_commit_rev > 0 else True)

          # revert again if last fetch has broke the HEAD

          git_remote_refspec_token, git_remote_local_refspec_token = \
            get_git_remote_refspec_token_tuple(remote_name, git_local_branch, git_remote_branch)

          # get last pushed commit hash
          git_last_pushed_commit_hash = get_git_last_pushed_commit_hash(git_reporoot, git_remote_local_refspec_token)

          git_local_refspec_token = get_git_local_refspec_token(git_local_branch, git_remote_branch)

          revert_if_git_head_refs_is_not_last_pushed(git_last_pushed_commit_hash, git_local_refspec_token, git_remote_refspec_token,
            reset_hard = reset_hard)

          # get fetch subtrees
          git_fetch_subtrees(git_repos_reader, scm_name, remote_name)

          print('---')

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

                parent_svn_repopath = parent_svn_reporoot + ('/' + parent_svn_path_prefix if parent_svn_path_prefix != '' else '')
                child_svn_repopath = child_svn_reporoot + ('/' + child_svn_path_prefix if child_svn_path_prefix != '' else '')

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
                  call_git(['log', '--format=commit: %H%ntimestamp: %ct%ndate_time: %ci%nauthor: %an <%ae>%n%b',
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

              parent_svn_repopath = parent_svn_reporoot + ('/' + parent_svn_path_prefix if parent_svn_path_prefix != '' else '')
              child_svn_repopath = child_svn_reporoot + ('/' + child_svn_path_prefix if child_svn_path_prefix != '' else '')

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
                call_git(['log', '--format=commit: %H%ntimestamp: %ct%ndate_time: %ci%nauthor: %an <%ae>%n%b',
                  get_git_remote_refspec_token(child_remote_name, child_git_local_branch, child_git_remote_branch),
                  '--since', str(parent_first_unpushed_svn_timestamp)], max_stdout_lines = 32)

              raise Exception('the child GIT repository `' + child_remote_name + '` is ahead to the parent GIT repository `' + parent_remote_name + '`')
          """

      # 3.
      #

      max_time_depth_in_multiple_svn_commits_fetch_sec = get_max_time_depth_in_multiple_svn_commits_fetch_sec()

      is_first_time_push = True

      while True:
        unpushed_svn_commit_by_timestamp_dict = collect_unpushed_svn_revisions_ordered_by_timestamp(git_svn_repo_tree_tuple_ref_preorder_list)
        if len(unpushed_svn_commit_by_timestamp_dict) == 0:
          raise Exception('unpushed_svn_commit_by_timestamp_dict is accidently empty')

        print('- GIT-SVN pushing is started.')

        min_tree_time_of_last_unpushed_svn_commit = get_min_tree_time_of_last_unpushed_svn_commit(git_svn_repo_tree_tuple_ref_preorder_list)

        for unpushed_svn_commit_timestamp, unpushed_svn_commit_list in sorted(unpushed_svn_commit_by_timestamp_dict.items()):
          for unpushed_svn_commit_tuple in unpushed_svn_commit_list:
            unpushed_svn_commit_datetime = unpushed_svn_commit_tuple[1]
            git_svn_repo_tree_tuple_ref = unpushed_svn_commit_tuple[2]

            repo_params_ref = git_svn_repo_tree_tuple_ref[0]
            fetch_state_ref = git_svn_repo_tree_tuple_ref[1]

            remote_name = repo_params_ref['remote_name']

            min_ro_tree_time_of_first_unpushed_svn_commit = get_min_ro_tree_time_of_first_unpushed_svn_commit(git_svn_repo_tree_tuple_ref)

            if not min_ro_tree_time_of_first_unpushed_svn_commit is None:
              min_ro_tree_time_of_first_unpushed_svn_commit_timestamp = min_ro_tree_time_of_first_unpushed_svn_commit[0]

              if unpushed_svn_commit_timestamp >= min_ro_tree_time_of_first_unpushed_svn_commit_timestamp:
                min_ro_tree_svn_commit_repo_tree_tuple_ref = min_ro_tree_time_of_first_unpushed_svn_commit[2]
                min_ro_tree_repo_params_ref = min_ro_tree_svn_commit_repo_tree_tuple_ref[0]
                min_ro_tree_remote_name = min_ro_tree_repo_params_ref['remote_name']
                raise Exception('The `' + min_ro_tree_remote_name +
                  '` read only repository must be pushed in an another project before continue with the `' + remote_name + '` repository from the current project')

            min_tree_time_of_last_unpushed_svn_commit = get_min_tree_time_of_last_unpushed_svn_commit(git_svn_repo_tree_tuple_ref_preorder_list)

            if not min_tree_time_of_last_unpushed_svn_commit is None:
              min_tree_time_of_last_unpushed_svn_commit_timestamp = min_tree_time_of_last_unpushed_svn_commit[0]

              if min_tree_time_of_last_unpushed_svn_commit_timestamp < unpushed_svn_commit_timestamp:
                break

            parent_tuple_ref = repo_params_ref['parent_tuple_ref']

            svn_reporoot = repo_params_ref['svn_reporoot']

            git_local_branch = repo_params_ref['git_local_branch']
            git_remote_branch = repo_params_ref['git_remote_branch']

            parent_git_path_prefix = repo_params_ref['parent_git_path_prefix']

            if not parent_tuple_ref is None:
              subtree_git_wcroot = os.path.abspath(os.path.join(subtrees_root, remote_name + "'" + parent_git_path_prefix.replace('/', '--'))).replace('\\', '/')

              print(' ->> cwd: `{0}`...'.format(subtree_git_wcroot))
            else:
              print(' ->> cwd: `{0}`...'.format(wcroot_path))

            with conditional(not parent_tuple_ref is None, local.cwd(subtree_git_wcroot) if not parent_tuple_ref is None else None):
              # generate `--ignore_paths` for subtrees

              git_svn_fetch_cmdline_list = []

              git_svn_fetch_ignore_paths_regex = get_git_svn_subtree_ignore_paths_regex(git_repos_reader, scm_name, remote_name, svn_reporoot)
              if len(git_svn_fetch_ignore_paths_regex) > 0:
                git_svn_fetch_cmdline_list.append('--ignore-paths=' + git_svn_fetch_ignore_paths_regex)

              unpushed_svn_commit_rev = unpushed_svn_commit_tuple[0]
              unpushed_svn_commit_datetime = unpushed_svn_commit_tuple[1]

              last_pushed_git_svn_commit = fetch_state_ref['last_pushed_git_svn_commit']
              last_pushed_git_svn_commit_rev = last_pushed_git_svn_commit[0]

              # direct use of the config section name `svn`
              call_git(['svn', 'fetch', 'svn', '-r' + str(unpushed_svn_commit_rev)] + git_svn_fetch_cmdline_list,
                ignore_warnings = False if last_pushed_git_svn_commit_rev > 0 else True)

              # CAUTION:
              #   1. We must check whether the revision was really fetched because related fetch directory may not yet/already exist
              #      (moved/deleted by the svn or completely filtered out by the `--ignore-paths` in the git) and if not, then get
              #      skip the rebase and the push, otherwise the rebase and followed commands may fail on actually a not fetched svn commit!
              #

              # ignore errors because may call on not yet existed branch
              ret = call_git_no_except(['log', '--max-count=1',
                '--format=commit: %H%ntimestamp: %ct%ndate_time: %ci%nauthor: %an <%ae>%n%b', 'refs/remotes/origin/git-svn-trunk'])

              git_first_commit_svn_rev, git_first_commit_hash, git_first_commit_timestamp = get_git_first_commit_from_git_log(ret[1])
              if git_first_commit_svn_rev == unpushed_svn_commit_rev:
                # the fetched svn revision is confirmed, can continue now

                # CAUTION:
                #   1. The `git svn rebase ...` can not handle unrelated histories properly, we have to use plain `git rebase ...` to handle that.
                #   2. We can not use `git rebase ...` either because the `git-svn-trunk` branch can be incomplete and consist only of a single
                #      and last one commit which can involve incorrect rebase with a fall back to the `patching base and 3-way merge`.
                #   3. Additionally, the `git rebase ..` can skip commits and make no action even if commits exists, so we have to track that behaviour.
                #
                #      So, to resolve all of these we have to use the `git cherry-pick ...` command instead to take commits one by one from
                #      unrelated histories unconditionally and arbitrary.
                #
                ##call_git(['svn', 'rebase', '-l'])
                ###git_local_refspec_token = get_git_local_refspec_token(git_local_branch, git_remote_branch)
                ###call_git(['rebase', git_local_refspec_token, 'refs/remotes/origin/git-svn-trunk'])

                call_git(['cherry-pick', '--allow-empty', git_first_commit_hash])

                # Change:
                #   1. Author name and email.
                #   2. Commit date.
                #
                author_svn_token = yaml_expand_global_string('${${SCM_NAME}.USER} <${${SCM_NAME}.EMAIL}>')
                call_git(['commit', '--amend', '--no-edit', '--allow-empty', '--author=' + author_svn_token, '--date', unpushed_svn_commit_datetime])

                # CAUTION:
                #   1. The previous `git commit --amend ...` command may change the last commit hash and detach it from the main branch,
                #      so we must update the main branch reference by the HEAD to make point the main branch to the HEAD again.
                #
                ret = call_git(['rev-parse', 'HEAD'])
                head_hash = ret[1].rstrip()

                if len(head_hash) > 0:
                  git_local_refspec_token = get_git_local_refspec_token(git_local_branch, git_remote_branch)
                  call_git(['update-ref', git_local_refspec_token, head_hash])

                git_push_refspec_token = get_git_push_refspec_token(git_local_branch, git_remote_branch)

                if not is_first_time_push:
                  call_git(['push', remote_name, git_push_refspec_token])
                else:
                  call_git(['push', '-u', remote_name, git_push_refspec_token])
              else:
                print('- Push skipped: svn commit was not found after in the last fetch: fetched=' + str(unpushed_svn_commit_rev) +
                  '; first_found=' + str(git_first_commit_svn_rev))

              # get fetch subtrees
              #git_fetch_subtrees(git_repos_reader, scm_name, remote_name)

        has_unpushed_svn_revisions_to_update = \
          update_git_svn_repo_fetch_state(git_svn_repo_tree_tuple_ref_preorder_list, max_time_depth_in_multiple_svn_commits_fetch_sec, first_time_update = False)
        if not has_unpushed_svn_revisions_to_update:
          break
