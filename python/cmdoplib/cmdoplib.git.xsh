# python module for commands with extension modules usage: tacklelib, plumbum

import os, sys, csv, shlex
from plumbum import local

tkl_source_module(SOURCE_DIR, 'cmdoplib.std.xsh')
tkl_source_module(SOURCE_DIR, 'cmdoplib.yaml.xsh')

tkl_import_module(TACKLELIB_ROOT, 'tacklelib.utils.py', 'tkl')

class GitReposListReaderDialect(csv.Dialect):
  delimiter = '|'
  quotechar = '"'
  doublequote = True
  skipinitialspace = True
  lineterminator = '\r\n'
  quoting = csv.QUOTE_MINIMAL

csv.register_dialect('git_repos_list', GitReposListReaderDialect)

class GitReposListReader:
  def __init__(self, file_path, fieldnames =
      ['scm_token', 'branch_type', 'remote_name', 'remote_url', 'local_branch', 'remote_branch', 'git_path_prefix', 'svn_path_prefix', 'git_remote_add_cmdline', 'git_subtree_cmdline'],
      dialect = 'git_repos_list'):
    self.file = open(file_path, newline='')
    # decomment based on: https://stackoverflow.com/questions/14158868/python-skip-comment-lines-marked-with-in-csv-dictreader/50592259#50592259
    self.dict_reader = csv.DictReader(GitReposListReader._decomment(self.file), fieldnames = fieldnames, dialect = dialect)
    self.fieldnames = fieldnames
    self.dialect = dialect

  def __enter__(self):
    return self

  def __exit__(self, exc_type, exc_value, trackback):
    self.close()

  def __iter__(self):
    return self.dict_reader

  @staticmethod
  def _decomment(csv_file):
    for row in csv_file:
        raw = row.split('#')[0].strip()
        if raw:
          yield raw

  def close(self):
    if self.dict_reader:
      self.dict_reader = None
    if self.file:
      self.file.close()
      self.file = None

  def reset(self):
    self.file.seek(0)
    self.dict_reader = csv.DictReader(GitReposListReader._decomment(self.file), fieldnames = self.fieldnames, dialect = self.dialect)

def git_init(configure_dir, scm_name):
  print(">git init: {0}".format(configure_dir))

  if configure_dir == '':
    print_err("{0}: error: configure directory is not defined.".format(sys.argv[0]))
    return 1

  if configure_dir[-1:] in ['\\', '/']:
    configure_dir = configure_dir[:-1]

  if not os.path.isdir(configure_dir):
    print_err("{0}: error: configure directory does not exist: `{1}`.".format(sys.argv[0], configure_dir))
    return 2

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

  with local.cwd(wcroot_path):
    if not os.path.exists(wcroot_path + '/.git'):
      call('git', ['init', wcroot_path])

    with GitReposListReader(configure_dir + '/git_repos.lst') as repos_reader:
      # generate `--ignore_paths` for subtrees
      git_svn_init_ignore_paths_regex = ''

      for row in repos_reader:
        if row['scm_token'] == scm_name and row['scm_token'] != 'root':
          svn_path_prefix = row['svn_path_prefix']
          svn_path_prefix_escaped = ''
          if svn_path_prefix != '.':
            # expand if contains a variable substitution
            svn_path_prefix_escaped = yaml_expand_value(svn_path_prefix)

            # convert all back slashes at first
            svn_path_prefix_escaped = svn_path_prefix_escaped.replace('\\', '/')

            # drop all regex special characters except the `^`
            for c in '\\$.+[](){}':
              svn_path_prefix_escaped = svn_path_prefix_escaped.replace(c, '\\' + c)

            if len(git_svn_init_ignore_paths_regex) > 0:
              git_svn_init_ignore_paths_regex = git_svn_init_ignore_paths_regex + '|' + svn_path_prefix_escaped + '(?:/|$)'
            else:
              git_svn_init_ignore_paths_regex = svn_path_prefix_escaped + '(?:/|$)'

      if len(git_svn_init_ignore_paths_regex) > 0:
        git_svn_init_cmdline.insert(0, '--ignore-paths="' + git_svn_init_ignore_paths_regex + '"')

      # (re)init git svn
      svn_reporoot = yaml_expand_value(getvar('SVN.REPOROOT'))

      if not os.path.exists(wcroot_path + '/.git/svn'):
        call('git', ['svn', 'init', svn_reporoot] + git_svn_init_cmdline)

      call('git', ['config', 'user.name', git_user])
      call('git', ['config', 'user.email', git_email])

      repos_reader.reset()

      # register git remotes
      for row in repos_reader:
        if row['scm_token'] == scm_name:
          remote_name = yaml_expand_value(row['remote_name'])
          remote_url = yaml_expand_value(row['remote_url'])

          ret = call_no_except('git', ['remote', 'get-url', remote_name], stdout = tkl.devnull(), stderr = tkl.devnull())
          if not ret[0]:
            call('git', ['remote', 'set-url', remote_name, remote_url])
          else:
            git_remote_add_cmdline = row['git_remote_add_cmdline']
            if git_remote_add_cmdline == '.':
              git_remote_add_cmdline = ''
            call('git', ['remote', 'add', remote_name, remote_url] + shlex.split(git_remote_add_cmdline))
