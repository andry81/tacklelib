# python module for commands with extension modules usage: tacklelib, plumbum

tkl_import_module(TACKLELIB_ROOT, 'tacklelib.utils.py', 'tkl')

tkl_source_module(CMDOPLIB_ROOT, 'cmdoplib.std.xsh')
tkl_source_module(CMDOPLIB_ROOT, 'cmdoplib.csvsvn.xsh')
tkl_source_module(CMDOPLIB_ROOT, 'cmdoplib.callsvn.xsh')

import os, sys, time, plumbum
from datetime import datetime # must be the same everythere

discover_executable('SVN_EXEC', 'svn', 'SVN')

call_svn(['--version'])

def get_svn_commit_list(svn_path, depth = 1, from_rev = None, to_rev = None):
  rev_list = []

  if from_rev is None:
    if str(to_rev) == '0':
      from_rev = 'HEAD'
    else:
      from_rev = 0

  if not to_rev is None:
    if depth != '*':
      ret = call_svn(['log', '-q', '-l', str(depth), '-r', str(from_rev) + ':' + str(to_rev), svn_path])
    else:
      ret = call_svn(['log', '-q', '-r', str(from_rev) + ':' + str(to_rev), svn_path])
  else:
    if depth != '*':
      ret = call_svn(['log', '-q', '-l', str(depth), '-r', str(from_rev), svn_path])
    else:
      ret = call_svn(['log', '-q', '-r', str(from_rev), svn_path])

  stdout_lines = ret[1].rstrip()
  stderr_lines = ret[2].rstrip()

  with SvnLogListReader(stdout_lines) as svn_log_reader:
    for row in svn_log_reader:
      svn_rev = row['rev']
      if svn_rev[:1] == 'r':
        svn_rev = int(svn_rev[1:].rstrip())
        svn_user_name = row['user_name'].rstrip()
        svn_date_time = row['date_time']
        found_index = svn_date_time.find('(')
        if found_index >= 0:
          svn_date_time = svn_date_time[:found_index]
        svn_date_time = svn_date_time.rstrip()

        svn_timestamp = int(time.mktime(datetime.strptime(svn_date_time, '%Y-%m-%d %H:%M:%S %z').timetuple()))
        rev_list.append((svn_rev, svn_user_name, svn_timestamp, svn_date_time))

  # cut out the middle of the stdout
  num_revs = len(rev_list)
  if num_revs > 7:
    row_index = 0
    for row in rev_list:
      if row_index < 3 or row_index >= num_revs - 3: # excluding the last line return
        print('r{} | {} | {} {{{}}}'.format(*row))
      elif row_index == 3:
        print('...')
      row_index += 1
  elif num_revs > 0:
    for row in rev_list:
      print('r{} | {} | {} {{{}}}'.format(*row))
  if len(stderr_lines) > 0:
    print(stderr_lines)

  return rev_list if len(rev_list) > 0 else None

def makedirs(configure_dir, scm_token, verbosity = None):
  print("makedirs: {0}".format(configure_dir))

  prev_verbosity_level = get_verbosity_level()
  with tkl.OnExit(lambda: set_verbosity_level(prev_verbosity_level)):
    set_verbosity_level(verbosity)

    if configure_dir == '':
      raise Exception('configure directory is not defined.')

    if configure_dir[-1:] in ['\\', '/']:
      configure_dir = configure_dir[:-1]

    if not os.path.isdir(configure_dir):
      raise Exception('configure directory does not exist: `{0}`.'.format(configure_dir))

    wcroot_dir_var = scm_token + '.WCROOT_DIR'
    wcroot_dir = getglobalvar(wcroot_dir_var)
    if wcroot_dir is None or wcroot_dir == '':
      raise Exception('variable is not defined or empty: `{0}`'.format(wcroot_dir_var))

    wcroot_offset = getglobalvar('WCROOT_OFFSET')
    if wcroot_offset is None or wcroot_offset == '':
      raise Exception('variable is not defined or empty: `{0}`'.format('WCROOT_OFFSET'))

    wcroot_path = os.path.abspath(os.path.join(wcroot_offset, wcroot_dir)).replace('\\', '/')

    if not os.path.exists(wcroot_path):
      print('  ' + wcroot_path)
      os.makedirs(wcroot_path)

  return 0

def svn_checkout(configure_dir, scm_token, bare_args, verbosity = None):
  print("svn checkout: {0}".format(configure_dir))

  prev_verbosity_level = get_verbosity_level()
  with tkl.OnExit(lambda: set_verbosity_level(prev_verbosity_level)):
    set_verbosity_level(verbosity)

    if len(bare_args) > 0:
      print('- args:', bare_args)

    if configure_dir == '':
      raise Exception('configure directory is not defined.')

    if configure_dir[-1:] in ['\\', '/']:
      configure_dir = configure_dir[:-1]

    if not os.path.isdir(configure_dir):
      raise Exception('configure directory does not exist: `{0}`.'.format(configure_dir))

    wcroot_dir_var = scm_token + '.WCROOT_DIR'
    wcroot_dir = getglobalvar(wcroot_dir_var)
    if wcroot_dir is None or wcroot_dir == '':
      raise Exception('variable is not defined or empty: `{0}`'.format(wcroot_dir_var))

    wcroot_offset = getglobalvar('WCROOT_OFFSET')
    if wcroot_offset is None or wcroot_offset == '':
      raise Exception('variable is not defined or empty: `{0}`'.format('WCROOT_OFFSET'))

    wcroot_path = os.path.abspath(os.path.join(wcroot_offset, wcroot_dir)).replace('\\', '/')

    svn_checkout_url = getglobalvar(scm_token + '.CHECKOUT_URL')

    print(' ->> wcroot: `{0}`'.format(wcroot_path))

    if not os.path.exists(wcroot_path):
      os.mkdir(wcroot_path)

    if os.path.isdir(wcroot_path + '/.svn'):
      return 0

    call_svn(['co', svn_checkout_url, wcroot_path] + bare_args, max_stdout_lines = -1)

  return 0

def svn_cleanup(configure_dir, scm_token, bare_args, verbosity = None):
  print("svn cleaup: {0}".format(configure_dir))

  prev_verbosity_level = get_verbosity_level()
  with tkl.OnExit(lambda: set_verbosity_level(prev_verbosity_level)):
    set_verbosity_level(verbosity)

    if len(bare_args) > 0:
      print('- args:', bare_args)

    if configure_dir == '':
      raise Exception('configure directory is not defined.')

    if configure_dir[-1:] in ['\\', '/']:
      configure_dir = configure_dir[:-1]

    if not os.path.isdir(configure_dir):
      raise Exception('configure directory does not exist: `{0}`.'.format(configure_dir))

    wcroot_dir_var = scm_token + '.WCROOT_DIR'
    wcroot_dir = getglobalvar(wcroot_dir_var)
    if wcroot_dir is None or wcroot_dir == '':
      raise Exception('variable is not defined or empty: `{0}`'.format(wcroot_dir_var))

    wcroot_offset = getglobalvar('WCROOT_OFFSET')
    if wcroot_offset is None or wcroot_offset == '':
      raise Exception('variable is not defined or empty: `{0}`'.format('WCROOT_OFFSET'))

    wcroot_path = os.path.abspath(os.path.join(wcroot_offset, wcroot_dir)).replace('\\', '/')

    with local_cwd(' ->> cwd: `{0}`...', ' -<< cwd: `{0}`...', wcroot_path):
      call_svn(['cleanup'] + bare_args, max_stdout_lines = -1)

  return 0

def svn_update(configure_dir, scm_token, bare_args, verbosity = None):
  print("svn update: {0}".format(configure_dir))

  prev_verbosity_level = get_verbosity_level()
  with tkl.OnExit(lambda: set_verbosity_level(prev_verbosity_level)):
    set_verbosity_level(verbosity)

    if len(bare_args) > 0:
      print('- args:', bare_args)

    if configure_dir == '':
      raise Exception('configure directory is not defined.')

    if configure_dir[-1:] in ['\\', '/']:
      configure_dir = configure_dir[:-1]

    if not os.path.isdir(configure_dir):
      raise Exception('configure directory does not exist: `{0}`.'.format(configure_dir))

    wcroot_dir_var = scm_token + '.WCROOT_DIR'
    wcroot_dir = getglobalvar(wcroot_dir_var)
    if wcroot_dir is None or wcroot_dir == '':
      raise Exception('variable is not defined or empty: `{0}`'.format(wcroot_dir_var))

    wcroot_offset = getglobalvar('WCROOT_OFFSET')
    if wcroot_offset is None or wcroot_offset == '':
      raise Exception('variable is not defined or empty: `{0}`'.format('WCROOT_OFFSET'))

    wcroot_path = os.path.abspath(os.path.join(wcroot_offset, wcroot_dir)).replace('\\', '/')

    with local_cwd(' ->> cwd: `{0}`...', ' -<< cwd: `{0}`...', wcroot_path):
      call_svn(['up'] + bare_args, max_stdout_lines = -1)

  return 0

def svn_relocate(configure_dir, scm_token, bare_args, verbosity = None):
  # dependent on declaration order in case of a direct usage (not through the `globals()['...']`), so must always be to avoid a dependency
  global g_registered_ignored_errors

  print("svn relocate: {0}".format(configure_dir))

  prev_verbosity_level = get_verbosity_level()
  with tkl.OnExit(lambda: set_verbosity_level(prev_verbosity_level)):
    set_verbosity_level(verbosity)

    if len(bare_args) > 0:
      print('- args:', bare_args)

    if configure_dir == '':
      raise Exception('configure directory is not defined.')

    if configure_dir[-1:] in ['\\', '/']:
      configure_dir = configure_dir[:-1]

    if not os.path.isdir(configure_dir):
      raise Exception('configure directory does not exist: `{0}`.'.format(configure_dir))

    wcroot_dir_var = scm_token + '.WCROOT_DIR'
    wcroot_dir = getglobalvar(wcroot_dir_var)
    if wcroot_dir is None or wcroot_dir == '':
      raise Exception('variable is not defined or empty: `{0}`'.format(wcroot_dir_var))

    wcroot_offset = getglobalvar('WCROOT_OFFSET')
    if wcroot_offset is None or wcroot_offset == '':
      raise Exception('variable is not defined or empty: `{0}`'.format('WCROOT_OFFSET'))

    wcroot_path = os.path.abspath(os.path.join(wcroot_offset, wcroot_dir)).replace('\\', '/')

    with local_cwd(' ->> cwd: `{0}`...', ' -<< cwd: `{0}`...', wcroot_path):
      try:
        call_svn(['relocate'] + bare_args, max_stdout_lines = -1)
      except plumbum.ProcessExecutionError as proc_err:
        proc_stdout = proc_err.stdout.rstrip()
        proc_stderr = proc_err.stderr.rstrip()

        # ignore non critical errors

        # `svn: E155024: Invalid source URL prefix: 'https://' (does not overlap target's URL 'svn+ssh://...')
        if proc_stderr.find('E155024: ') < 0:
          raise

        g_registered_ignored_errors.append((' -> `' + configure_dir + '`', proc_stderr))

  return 0
