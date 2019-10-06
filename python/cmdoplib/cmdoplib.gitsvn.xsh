# python module for commands with extension modules usage: tacklelib, plumbum

import os, sys, io, csv, shlex, copy
from plumbum import local

tkl_source_module(SOURCE_DIR, 'cmdoplib.std.xsh')
tkl_source_module(SOURCE_DIR, 'cmdoplib.yaml.xsh')
tkl_source_module(SOURCE_DIR, 'cmdoplib.csvgit.xsh')
tkl_source_module(SOURCE_DIR, 'cmdoplib.url.xsh')
tkl_source_module(SOURCE_DIR, 'cmdoplib.svn.xsh')

tkl_import_module(TACKLELIB_ROOT, 'tacklelib.utils.py', 'tkl')

def get_git_svn_path_prefix_regex(path):
  # convert all back slashes at first
  git_svn_path_prefix_regex = path.replace('\\', '/')

  # escape all regex characters
  for c in '^$.+[](){}':
    git_svn_path_prefix_regex = git_svn_path_prefix_regex.replace(c, '\\' + c)

  return '^' + git_svn_path_prefix_regex + '(?:/|$)'

def validate_git_refspec(local_branch, remote_branch):
  if local_branch == '.': local_branch = ''
  if remote_branch == '.': remote_branch = ''

  if local_branch != '' and remote_branch == '':
    remote_branch = local_branch
  elif local_branch == '' and remote_branch != '':
    local_branch = remote_branch
  elif local_branch == '' and remote_branch == '':
    raise Exception("at least one of local_branch and remote_branch parameters must be a valid branch name")

  return (local_branch, remote_branch)

def get_git_pull_refspec_token(local_branch, remote_branch):
  local_branch, remote_branch == validate_git_refspec(local_branch, remote_branch)

  if local_branch == remote_branch:
    refspec_token = local_branch
  else:
    refspec_token = remote_branch + ':' + local_branch

  return refspec_token

def get_git_local_ref_token(local_branch, remote_branch):
  return 'refs/heads/' + validate_git_refspec(local_branch, remote_branch)[0]

def get_git_remote_ref_token(remote_name, local_branch, remote_branch):
  return 'refs/remotes/' + remote_name + '/' + validate_git_refspec(local_branch, remote_branch)[1]

def get_git_fetch_refspec_token(local_branch, remote_branch):
  local_branch, remote_branch = validate_git_refspec(local_branch, remote_branch)

  if local_branch == remote_branch:
    refspec_token = local_branch
  else:
    refspec_token = remote_branch + ':refs/heads/' + local_branch

  return refspec_token

def register_git_remotes(git_repos_reader, scm_name, remote_name, with_root):
  git_repos_reader.reset()

  if with_root:
    for root_row in git_repos_reader:
      if root_row['scm_token'] == scm_name and root_row['remote_name'] == remote_name:
        root_remote_name = yaml_expand_value(root_row['remote_name'])
        root_git_reporoot = yaml_expand_value(root_row['git_reporoot'])

        ret = call_no_except('git', ['remote', 'get-url', root_remote_name], stdout = tkl.devnull(), stderr = tkl.devnull())
        if not ret[0]:
          call('git', ['remote', 'set-url', root_remote_name, root_git_reporoot])
        else:
          git_remote_add_cmdline = root_row['git_remote_add_cmdline']
          if git_remote_add_cmdline == '.':
            git_remote_add_cmdline = ''
          call('git', ['remote', 'add', root_remote_name, root_git_reporoot] + shlex.split(git_remote_add_cmdline))
        break

    git_repos_reader.reset()

  for subtree_row in git_repos_reader:
    if subtree_row['scm_token'] == scm_name and subtree_row['parent_remote_name'] == remote_name:
      subtree_remote_name = yaml_expand_value(subtree_row['remote_name'])
      subtree_git_reporoot = yaml_expand_value(subtree_row['git_reporoot'])

      ret = call_no_except('git', ['remote', 'get-url', subtree_remote_name], stdout = tkl.devnull(), stderr = tkl.devnull())
      if not ret[0]:
        call('git', ['remote', 'set-url', subtree_remote_name, subtree_git_reporoot])
      else:
        git_remote_add_cmdline = subtree_row['git_remote_add_cmdline']
        if git_remote_add_cmdline == '.':
          git_remote_add_cmdline = ''
        call('git', ['remote', 'add', subtree_remote_name, subtree_git_reporoot] + shlex.split(git_remote_add_cmdline))

# ex: `git checkout -b <local_branch> refs/remotes/origin/<remote_branch>`
#
def get_git_checkout_branch_args_list(remote_name, local_branch, remote_branch):
  local_branch, remote_branch == validate_git_refspec(local_branch, remote_branch)

  return ['-b', local_branch, get_git_remote_ref_token(remote_name, local_branch, remote_branch)]

"""
def get_git_fetch_first_commit_hash(remote_name, local_branch, remote_branch):
  first_commit_hash = None

  ret = call_no_except('git', ['rev-list', '--reverse', '--max-parents=0', 'FETCH_HEAD', get_git_remote_ref_token(remote_name, local_branch, remote_branch)], stdout = None, stderr = None)
  for row in io.StringIO(ret[1]):
    first_commit_hash = row
    break

  if not first_commit_hash is None:
    print(first_commit_hash)
  if len(ret[2]) > 0:
    print(ret[2])

  return first_commit_hash.strip()
"""

# Returns only the first git commit parameters or nothing.
#
def get_git_first_commit_from_git_log(str):
  svn_rev = None
  commit_hash = None
  commit_timestamp = None

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
        svn_rev = git_svn_url[svn_rev_index + 1:]

  return (svn_rev, commit_hash, commit_timestamp)

# Returns the git commit parameters where was found the svn revision under the requested remote svn url, otherwise would return the last commit parameters.
#
def get_git_commit_from_git_log(str, svn_reporoot, svn_path_prefix):
  if svn_path_prefix == '.': svn_path_prefix = ''

  svn_remote_path = svn_reporoot + ('/' + svn_path_prefix if svn_path_prefix != '' else '')

  num_commits = 0

  lines = io.StringIO(str)
  for line in lines:
    print(line.strip())
    value_list = [value.strip() for value in line.split(":", 1)]
    key = value_list[0]
    if key == 'commit':
      commit_hash = value_list[1]
      num_commits += 1
    elif key == 'timestamp':
      commit_timestamp = value_list[1]
    elif key == 'git-svn-id':
      git_svn_url = value_list[1].split(' ', 1)[0]
      svn_rev_index = git_svn_url.rfind('@')
      if svn_rev_index > 0:
        svn_path = git_svn_url[:svn_rev_index]
        svn_rev = git_svn_url[svn_rev_index + 1:]
        if svn_path == svn_remote_path:
          return (svn_rev, commit_hash, commit_timestamp, num_commits)

  return (None, commit_hash, commit_timestamp, num_commits)

def get_last_git_pushed_commit_hash(git_reporoot, git_local_ref_token):
  git_last_pushed_commit_hash = None

  ret = call_no_except('git', ['ls-remote', git_reporoot], stdout = None, stderr = None)
  print(ret[1])
  if len(ret[2]) > 0: print(ret[2])

  with GitLsRemoteListReader(ret[1]) as git_ls_remote_reader:
    for row in git_ls_remote_reader:
      if row['ref'] == git_local_ref_token:
        git_last_pushed_commit_hash = row['hash']
        break

  return git_last_pushed_commit_hash

def get_last_git_fetched_commit_hash(git_remote_ref_token):
  git_last_fetched_commit_hash = None

  ret = call('git', ['show-ref', '--verify', git_remote_ref_token], stdout = None, stderr = None)

  with GitShowRefListReader(ret[1]) as git_show_ref_reader:
    for row in git_show_ref_reader:
      if row['ref'] == git_remote_ref_token:
        git_last_fetched_commit_hash = row['hash']
        break

  if not git_last_fetched_commit_hash is None:
    print(git_last_fetched_commit_hash)
  if len(ret[2]):
    print(ret[2])

  return git_last_fetched_commit_hash

def get_git_head_commit_hash(git_local_ref_token):
  git_head_commit_hash = None

  ret = call_no_except('git', ['show-ref', '--verify', git_local_ref_token], stdout = None, stderr = None)

  with GitShowRefListReader(ret[1]) as git_show_ref_reader:
    for row in git_show_ref_reader:
      if row['ref'] == git_local_ref_token:
        git_head_commit_hash = row['hash']
        break

  if not git_head_commit_hash is None:
    print(git_head_commit_hash)
  if len(ret[2]):
    print(ret[2])

  return git_head_commit_hash

def revert_if_git_head_refs_is_not_last_pushed(git_reporoot, git_local_ref_token, git_remote_ref_token):
  # get last pushed commit hash

  git_last_pushed_commit_hash = get_last_git_pushed_commit_hash(git_reporoot, git_local_ref_token)

  # compare the last pushed commit hash with the last fetched commit hash and if different, then revert local changes

  # get last fetched commit hash

  if not git_last_pushed_commit_hash is None: # optimization
    git_last_fetched_commit_hash = get_last_git_fetched_commit_hash(git_remote_ref_token)

  if (not git_last_pushed_commit_hash is None and not git_last_fetched_commit_hash is None and git_last_pushed_commit_hash != git_last_fetched_commit_hash) or \
     (git_last_pushed_commit_hash is None and not git_last_fetched_commit_hash is None) or \
     (not git_last_pushed_commit_hash is None and git_last_fetched_commit_hash is None):
     call('git', ['reset', '--hard', git_remote_ref_token])

  # additionally, compare the last pushed commit hash with the head commit hash and if different then revert changes

  # get head commit hash

  git_head_commit_hash = get_git_head_commit_hash(git_local_ref_token)

  if (not git_last_pushed_commit_hash is None and not git_head_commit_hash is None and git_last_pushed_commit_hash != git_head_commit_hash) or \
     (git_last_pushed_commit_hash is None and not git_head_commit_hash is None):
     call('git', ['reset', '--hard', git_local_ref_token])


def get_git_svn_subtree_ignore_paths_regex(git_repos_reader, scm_name, remote_name, svn_reporoot):
  parent_svn_reporoot_urlpath = tkl.ParseResult('', *tkl.urlparse(svn_reporoot)[1:]).geturl()

  subtree_git_svn_init_ignore_paths_regex = ''

  git_repos_reader.reset()

  for subtree_row in git_repos_reader:
    if subtree_row['scm_token'] == scm_name and subtree_row['parent_remote_name'] == remote_name:
      svn_reporoot_urlpath = tkl.ParseResult('', *tkl.urlparse(subtree_row['svn_reporoot'])[1:]).geturl()

      if svn_reporoot_urlpath == parent_svn_reporoot_urlpath:
        subtree_svn_path_prefix = subtree_row['svn_path_prefix']

        if subtree_svn_path_prefix == '.':
          raise Exception('not root branch type must have not empty svn path prefix')

        subtree_svn_path_prefix = yaml_expand_value(subtree_svn_path_prefix)

        subtree_git_svn_path_prefix_regex = get_git_svn_path_prefix_regex(subtree_svn_path_prefix)

        subtree_git_svn_init_ignore_paths_regex += ('|' if len(subtree_git_svn_init_ignore_paths_regex) > 0 else '') + subtree_git_svn_path_prefix_regex

  return subtree_git_svn_init_ignore_paths_regex

def git_svn_fetch_to_last_git_pushed_svn_rev(remote_name, local_branch, remote_branch, svn_reporoot, svn_path_prefix, git_svn_fetch_cmdline_list = []):
  # search for the last pushed svn revision

  git_last_svn_rev, git_commit_hash, git_commit_timestamp, git_from_commit_timestamp, num_git_commits = \
    get_last_git_svn_rev_by_git_log(remote_name, local_branch, remote_branch, svn_reporoot, svn_path_prefix)

  # special `git svn fetch` call to build initial git-svn revisions map from the svn repository

  try:
    if not git_last_svn_rev is None:
      ret = call('git', ['svn', 'fetch', '-r' + str(git_last_svn_rev)] + git_svn_fetch_cmdline_list, stdout = None, stderr = None)
    else:
      ret = call('git', ['svn', 'fetch', '-r0'] + git_svn_fetch_cmdline_list, stdout = None, stderr = None)

  except ProcessExecutionError as proc_err:
    if len(proc_err.stdout) > 0:
      print(proc_err.stdout)
    if len(proc_err.stderr) > 0:
      print(proc_err.stderr)
    raise

  else:
    # cut out the middle of the stdout
    stdout_lines = ret[1]
    stderr_lines = ret[2]
    num_new_lines = stdout_lines.count('\n')
    if num_new_lines > 7:
      line_index = 0
      for line in io.StringIO(stdout_lines):
        if line_index < 3 or line_index >= num_new_lines - 3: # excluding the last line return
          print(line, end='')
        elif line_index == 3:
          print('...')
        line_index += 1
    elif len(stdout_lines) > 0:
      print(stdout_lines)
    if len(stderr_lines) > 0:
      print(stderr_lines)

  return git_last_svn_rev

# returns as tuple:
#   git_last_svn_rev          - last pushed svn revision if has any
#   git_commit_hash           - git commit associated with the last pushed svn revision if has any, otherwise the last git commit
#   git_commit_timestamp      - git commit timestamp of the `git_commit_hash` commit
#   git_from_commit_timestamp - from there the last search is occured, if None - from FETCH_HEAD, if not None, then has used as: `git log ... FETCH_HEAD ... --until <git_from_commit_timestamp>`
#   num_git_commits           - number of looked up commits from the either FETCH_HEAD or from the `git_from_commit_timestamp` argument in the last `git log` command
#
def get_last_git_svn_rev_by_git_log(remote_name, local_branch, remote_branch, svn_reporoot, svn_path_prefix, git_log_start_depth = 16):
  # get last pushed svn revision from the `git log` using last commit hash from the git remote repo
  git_last_svn_rev = None
  git_commit_hash = None
  git_commit_timestamp = None
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
    ret = call('git', ['log', '--max-count=' + str(git_log_next_depth), '--format=commit: %H%ntimestamp: %ct%n%b', 'FETCH_HEAD',
      get_git_remote_ref_token(remote_name, local_branch, remote_branch)] +
      (['--until', str(git_from_commit_timestamp)] if not git_from_commit_timestamp is None else []),
      stdout = None, stderr = None)

    git_last_svn_rev, git_commit_hash, git_commit_timestamp, num_git_commits = get_git_commit_from_git_log(ret[1], svn_reporoot, svn_path_prefix)

    # quit if the svn revision is found
    if not git_last_svn_rev is None:
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

  return (git_last_svn_rev, git_commit_hash, git_commit_timestamp, git_from_commit_timestamp, num_git_commits)


# CAUTION:
#   * By default the function initializes ONLY the root repository and does NOT initialize subtree repositories separately.
#     If you want later to fetch subtree repositories separately into stanalone working copies
#     (it is a requirement ONLY for the svn2git synchronization), then use the `fetch_subtrees_root` argument as a root path inside the root path).
#
def git_init(configure_dir, scm_name, fetch_subtrees_root = None, fetch_subtrees_builtin_root = False):
  print(">git init: {0}".format(configure_dir))

  if configure_dir == '':
    print_err("{0}: error: configure directory is not defined.".format(sys.argv[0]))
    return 1

  if not fetch_subtrees_root is None and fetch_subtrees_builtin_root:
    print_err("{0}: error: either fetch_subtrees_root or fetch_subtrees_builtin_root must be used at a time: fetch_subtrees_root=`{0}` fetch_subtrees_builtin_root=`{1}`."
      .format(sys.argv[0], fetch_subtrees_root, fetch_subtrees_builtin_root))
    return 2

  if configure_dir[-1:] in ['\\', '/']:
    configure_dir = configure_dir[:-1]

  if not os.path.isdir(configure_dir):
    print_err("{0}: error: configure directory does not exist: `{1}`.".format(sys.argv[0], configure_dir))
    return 32

  if not fetch_subtrees_root is None and not os.path.isdir(fetch_subtrees_root):
    print_err("{0}: error: fetch_subtrees_root directory does not exist: `{1}`.".format(sys.argv[0], fetch_subtrees_root))
    return 33

  wcroot_dir = getvar(scm_name + '.WCROOT_DIR')
  if wcroot_dir == '': return -254
  if WCROOT_OFFSET == '': return -253

  wcroot_path = os.path.abspath(os.path.join(WCROOT_OFFSET, wcroot_dir)).replace('\\', '/')

  git_user = getvar(scm_name + '.USER')
  git_email = getvar(scm_name + '.EMAIL')

  print(' -> {0}...'.format(wcroot_path))

  if not os.path.exists(wcroot_path):
    os.mkdir(wcroot_path)

  with local.cwd(wcroot_path):
    if not os.path.exists(wcroot_path + '/.git'):
      call('git', ['init', wcroot_path])

    with GitReposListReader(configure_dir + '/git_repos.lst') as git_repos_reader:
      git_svn_init_cmdline = getvar(scm_name + '.GIT_SVN_INIT_CMDLINE')

      # generate `--ignore_paths` for subtrees

      root_remote_name = None

      for row in git_repos_reader:
        if row['scm_token'] == scm_name and row['branch_type'] == 'root':
          root_remote_name = yaml_expand_value(row['remote_name'])
          root_svn_reporoot = yaml_expand_value(row['svn_reporoot'])
          root_svn_path_prefix = yaml_expand_value(row['svn_path_prefix'])
          break

      if root_remote_name is None:
        raise Exception('the root record is not found in the git repositories list')

      git_svn_init_ignore_paths_regex = get_git_svn_subtree_ignore_paths_regex(git_repos_reader, scm_name, root_remote_name, root_svn_reporoot)
      if len(git_svn_init_ignore_paths_regex) > 0:
        git_svn_init_cmdline.append('--ignore-paths=' + git_svn_init_ignore_paths_regex)

      if not os.path.exists(wcroot_path + '/.git/svn'):
        # (re)init git svn
        root_svn_url = root_svn_reporoot + '/' + root_svn_path_prefix

        call('git', ['svn', 'init', root_svn_url] + git_svn_init_cmdline)

      call('git', ['config', 'user.name', git_user])
      call('git', ['config', 'user.email', git_email])

      # register git remotes

      register_git_remotes(git_repos_reader, scm_name, root_remote_name, True)

      if fetch_subtrees_builtin_root:
        fetch_subtrees_root = wcroot_path + '/.git/svn2git/gitwc'

      if not fetch_subtrees_root is None:
        # Initialize non root git repositories as stanalone working copies inside the `fetch_subtrees_root` directory,
        # use the combination of the `remote_name` and the `parent_git_path_prefix` as a prefix to a working copy directory.

        git_repos_reader.reset()

        for subtree_row in git_repos_reader:
          if subtree_row['scm_token'] == scm_name and subtree_row['branch_type'] != 'root':
            subtree_parent_git_path_prefix = subtree_row['parent_git_path_prefix']

            if subtree_parent_git_path_prefix == '.':
              raise Exception('not root branch type must have not empty git parent path prefix')

            subtree_remote_name = yaml_expand_value(subtree_row['remote_name'])
            subtree_svn_reporoot = yaml_expand_value(subtree_row['svn_reporoot'])
            # expand if contains a variable substitution
            subtree_parent_git_path_prefix = yaml_expand_value(subtree_parent_git_path_prefix)
            subtree_svn_path_prefix = yaml_expand_value(subtree_row['svn_path_prefix'])

            subtree_git_wcroot = os.path.abspath(os.path.join(fetch_subtrees_root, subtree_remote_name + '--' + subtree_parent_git_path_prefix.replace('/', '--'))).replace('\\', '/')

            if fetch_subtrees_builtin_root:
              if not os.path.exists(fetch_subtrees_root):
                print('>mkdir: -p ' + fetch_subtrees_root)
                try:
                  os.makedirs(fetch_subtrees_root)
                except FileExistsError:
                  pass

            if not os.path.exists(subtree_git_wcroot):
              print('>mkdir: ' + subtree_git_wcroot)
              try:
                os.mkdir(subtree_git_wcroot)
              except FileExistsError:
                pass

            print(' ->> {0}...'.format(subtree_git_wcroot))

            with local.cwd(subtree_git_wcroot):
              if not os.path.exists(subtree_git_wcroot + '/.git'):
                call('git', ['init', subtree_git_wcroot])

              subtree_git_svn_init_cmdline = []

              with GitReposListReader(configure_dir + '/git_repos.lst') as subtree_git_repos_reader:
                # generate `--ignore_paths` for subtrees

                subtree_git_svn_init_ignore_paths_regex = get_git_svn_subtree_ignore_paths_regex(subtree_git_repos_reader, scm_name, subtree_remote_name, subtree_svn_reporoot)
                if len(subtree_git_svn_init_ignore_paths_regex) > 0:
                  subtree_git_svn_init_cmdline.append('--ignore-paths=' + subtree_git_svn_init_ignore_paths_regex)

                # (re)init subtree git svn
                svn_url = subtree_svn_reporoot + '/' + subtree_svn_path_prefix

                if not os.path.exists(subtree_git_wcroot + '/.git/svn'):
                  call('git', ['svn', 'init', subtree_svn_reporoot] + subtree_git_svn_init_cmdline)

                call('git', ['config', 'user.name', git_user])
                call('git', ['config', 'user.email', git_email])

                # register git remotes

                register_git_remotes(subtree_git_repos_reader, scm_name, subtree_remote_name, True)

# CAUTION:
#   * By default the function fetches ONLY the root repository and does NOT fetch subtree repositories separately.
#     If you want to fetch subtree repositories separately into stanalone working copies
#     (it is a requirement ONLY for the svn2git synchronization), then use the `fetch_subtrees_root` argument as a root path inside the root path).
#
def git_fetch(configure_dir, scm_name, fetch_subtrees_root = None, fetch_subtrees_builtin_root = False):
  print(">git pull: {0}".format(configure_dir))

  if not fetch_subtrees_root is None:
    print(' * fetch_subtrees_root: `' + fetch_subtrees_root + '`')

  if configure_dir == '':
    print_err("{0}: error: configure directory is not defined.".format(sys.argv[0]))
    return 1

  if not fetch_subtrees_root is None and fetch_subtrees_builtin_root:
    print_err("{0}: error: either fetch_subtrees_root or fetch_subtrees_builtin_root must be used at a time: fetch_subtrees_root=`{0}` fetch_subtrees_builtin_root=`{1}`."
      .format(sys.argv[0], fetch_subtrees_root, fetch_subtrees_builtin_root))
    return 2

  if configure_dir[-1:] in ['\\', '/']:
    configure_dir = configure_dir[:-1]

  if not os.path.isdir(configure_dir):
    print_err("{0}: error: configure directory does not exist: `{1}`.".format(sys.argv[0], configure_dir))
    return 32

  if not fetch_subtrees_root is None and not os.path.isdir(fetch_subtrees_root):
    print_err("{0}: error: fetch_subtrees_root directory does not exist: `{1}`.".format(sys.argv[0], fetch_subtrees_root))
    return 33

  wcroot_dir = getvar(scm_name + '.WCROOT_DIR')
  if wcroot_dir == '': return -254
  if WCROOT_OFFSET == '': return -253

  wcroot_path = os.path.abspath(os.path.join(WCROOT_OFFSET, wcroot_dir)).replace('\\', '/')

  git_svn_init_cmdline = getvar(scm_name + '.GIT_SVN_INIT_CMDLINE')
  git_user = getvar(scm_name + '.USER')
  git_email = getvar(scm_name + '.EMAIL')

  print(' -> {0}...'.format(wcroot_path))

  if not os.path.exists(wcroot_path):
    os.mkdir(wcroot_path)

  with local.cwd(wcroot_path), GitReposListReader(configure_dir + '/git_repos.lst') as git_repos_reader:
    has_root = False

    for row in git_repos_reader:
      # fetch the root

      if row['scm_token'] == scm_name and row['branch_type'] == 'root':
        has_root = True

        root_remote_name = yaml_expand_value(row['remote_name'])
        root_git_reporoot = yaml_expand_value(row['git_reporoot'])
        root_svn_reporoot = yaml_expand_value(row['svn_reporoot'])

        local_branch = yaml_expand_value(row['local_branch'])
        remote_branch = yaml_expand_value(row['remote_branch'])

        root_svn_path_prefix = yaml_expand_value(row['svn_path_prefix'])

        git_fetch_refspec_token = get_git_fetch_refspec_token(local_branch, remote_branch)

        call('git', ['fetch', root_remote_name, git_fetch_refspec_token])

        git_local_ref_token = get_git_local_ref_token(local_branch, remote_branch)

        """
        # update HEAD ref
        with open('.git/HEAD', 'wt') as head_file:
          head_file.write('ref: ' + git_local_ref_token)
          head_file.close()
        """

        """
        git_checkout_branch_args_list = get_git_checkout_branch_args_list(root_remote_name, local_branch, remote_branch)

        call('git', ['checkout'] + git_checkout_branch_args_list)
        """

        break

    if not has_root:
      raise Exception('Have has no root branch in the git_repos.lst')

    git_remote_ref_token = get_git_remote_ref_token(root_remote_name, local_branch, remote_branch)

    # 1. compare the last pushed commit hash with the last fetched commit hash and if different, then revert FETCH_HEAD
    # 2. additionally, compare the last pushed commit hash with the head commit hash and if different then revert HEAD

    revert_if_git_head_refs_is_not_last_pushed(root_git_reporoot, git_local_ref_token, git_remote_ref_token)

    # provoke git svn revisions rebuild

    git_svn_fetch_cmdline_list = []

    # generate `--ignore_paths` for subtrees

    git_svn_fetch_ignore_paths_regex = get_git_svn_subtree_ignore_paths_regex(git_repos_reader, scm_name, root_remote_name, root_svn_reporoot)
    if len(git_svn_fetch_ignore_paths_regex) > 0:
      git_svn_fetch_cmdline_list.append('--ignore-paths=' + git_svn_fetch_ignore_paths_regex)

    # git-svn (re)fetch last svn revision (faster than (re)fetch all revisions)

    git_last_svn_rev = git_svn_fetch_to_last_git_pushed_svn_rev(root_remote_name, local_branch, remote_branch, root_svn_reporoot, root_svn_path_prefix, git_svn_fetch_cmdline_list)

    if fetch_subtrees_builtin_root:
      fetch_subtrees_root = wcroot_path + '/.git/svn2git/gitwc'

    if not fetch_subtrees_root is None:
      # Fetch content of non root git repositories into stanalone working copies inside the `fetch_subtrees_root` directory,
      # use the combination of the `remote_name` and the `parent_git_path_prefix` as a prefix to a working copy directory.

      git_repos_reader.reset()

      for subtree_row in git_repos_reader:
        if subtree_row['scm_token'] == scm_name and subtree_row['branch_type'] != 'root':
          subtree_parent_git_path_prefix = subtree_row['parent_git_path_prefix']

          if subtree_parent_git_path_prefix == '.':
            raise Exception('not root branch type must have not empty git subtree path prefix')

          # expand if contains a variable substitution
          subtree_parent_git_path_prefix = yaml_expand_value(subtree_parent_git_path_prefix)
          subtree_remote_name = yaml_expand_value(subtree_row['remote_name'])

          subtree_git_wcroot = os.path.abspath(os.path.join(fetch_subtrees_root, subtree_remote_name + '--' + subtree_parent_git_path_prefix.replace('/', '--'))).replace('\\', '/')

          print(' ->> {0}...'.format(subtree_git_wcroot))

          with local.cwd(subtree_git_wcroot):
            subtree_remote_name = yaml_expand_value(subtree_row['remote_name'])
            subtree_git_reporoot = yaml_expand_value(subtree_row['git_reporoot'])
            subtree_svn_reporoot = yaml_expand_value(subtree_row['svn_reporoot'])

            subtree_local_branch = yaml_expand_value(subtree_row['local_branch'])
            subtree_remote_branch = yaml_expand_value(subtree_row['remote_branch'])

            subtree_svn_path_prefix = yaml_expand_value(subtree_row['svn_path_prefix'])

            subtree_git_fetch_refspec_token = get_git_fetch_refspec_token(subtree_local_branch, subtree_remote_branch)

            call('git', ['fetch', subtree_remote_name, subtree_git_fetch_refspec_token])

            subtree_git_local_ref_token = get_git_local_ref_token(subtree_local_branch, subtree_remote_branch)

            """
            # update HEAD ref
            with open('.git/HEAD', 'wt') as subtree_head_file:
              subtree_head_file.write('ref: ' + subtree_git_local_ref_token)
              subtree_head_file.close()
            """

            subtree_git_remote_ref_token = get_git_remote_ref_token(subtree_remote_name, subtree_local_branch, subtree_remote_branch)

            # 1. compare the last pushed commit hash with the last fetched commit hash and if different, then revert FETCH_HEAD
            # 2. additionally, compare the last pushed commit hash with the head commit hash and if different then revert HEAD

            revert_if_git_head_refs_is_not_last_pushed(subtree_git_reporoot, subtree_git_local_ref_token, subtree_git_remote_ref_token)

            # provoke git svn revisions rebuild

            subtree_git_svn_fetch_cmdline_list = []

            with GitReposListReader(configure_dir + '/git_repos.lst') as subtree_git_repos_reader:
              # generate `--ignore_paths` for subtrees

              subtree_git_svn_fetch_ignore_paths_regex = get_git_svn_subtree_ignore_paths_regex(subtree_git_repos_reader, scm_name, subtree_remote_name, subtree_svn_reporoot)
              if len(subtree_git_svn_fetch_ignore_paths_regex) > 0:
                subtree_git_svn_fetch_cmdline_list.append('--ignore-paths=' + subtree_git_svn_fetch_ignore_paths_regex)

              # git-svn (re)fetch last svn revision (faster than (re)fetch all revisions)

              subtree_git_last_svn_rev = \
                git_svn_fetch_to_last_git_pushed_svn_rev(subtree_remote_name, subtree_local_branch, subtree_remote_branch, subtree_svn_reporoot, subtree_svn_path_prefix, subtree_git_svn_fetch_cmdline_list)
