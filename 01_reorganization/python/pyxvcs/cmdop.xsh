import os, sys, inspect, argparse
import collections
#from datetime import datetime

if not hasattr(globals(), 'tkl_init'):
  # portable import to the global space
  sys.path.append(os.environ['TACKLELIB_PYTHON_SCRIPTS_ROOT'])
  import tacklelib as tkl

  tkl.tkl_init(tkl, global_config = {'log_import_module':os.environ.get('TACKLELIB_LOG_IMPORT_MODULE')})

  # cleanup
  del tkl # must be instead of `tkl = None`, otherwise the variable would be still persist
  sys.path.pop()


# basic initialization, loads `config.private.yaml`
tkl_source_module(SOURCE_DIR, '__init__.xsh')

tkl_import_module(CMDOPLIB_PYTHON_SCRIPTS_ROOT, 'cmdoplib.svn.xsh', 'cmdoplib_svn')
tkl_import_module(CMDOPLIB_PYTHON_SCRIPTS_ROOT, 'cmdoplib.gitsvn.xsh', 'cmdoplib_gitsvn')


# script arguments parse
for i in [
  ('dir', 1, 'CONFIGURE_OUTPUT_ROOT'),
  ('dir', 2, 'CONFIGURE_ROOT'),
  ('dir', 3, 'CONFIGURE_DIR'),
  ('str', 4, 'SCM_TOKEN'),
  ('str', 5, 'CMD_TOKEN')]:
  global_var_value = sys.argv[i[1]] if len(sys.argv) >= i[1] + 1 else ''
  if i[0] == 'dir':
    if global_var_value != '':
      global_var_value = os.path.abspath(global_var_value).replace('\\', '/')
    if not os.path.isdir(global_var_value):
      raise Exception('{0} directory does not exist: `{1}`'.format(i[2], global_var_value))
  elif i[0] == 'str':
    if global_var_value == '':
      raise Exception('{0} argument must not be empty'.format(i[2]))
  setglobalvar(i[2], global_var_value)


def get_supported_scm_list():
  return ['svn', 'git']

def validate_vars(configure_dir, scm_token):
  if configure_dir == '':
    raise Exception("configure directory is not defined")

  if configure_dir[-1:] in ['\\', '/']:
    configure_dir = configure_dir[:-1]

  if not os.path.isdir(configure_dir):
    raise Exception("configure directory does not exist: `{0}`.".format(configure_dir))

  hub_abbr_var = scm_token + '.HUB_ABBR'
  if not cmdop.hasglobalvar(hub_abbr_var):
    raise Exception("hub abbrivation variable is not declared for the scm_token as prefix: `{0}`.".format(hub_abbr_var))

  hub_abbr = cmdop.getglobalvar(hub_abbr_var)
  scm_type = scm_token[:3].lower()

  return (configure_dir, hub_abbr, scm_type)

def cmdop(configure_dir, scm_token, cmd_token, bare_args,
          git_subtrees_root = None, svn_subtrees_root = None,
          compare_remote_name = None, compare_svn_rev = None,
          root_only = False, reset_hard = False,
          remove_svn_on_reset = False, cleanup_on_reset = False, cleanup_on_compare = False,
          verbosity = None, prune_empty_git_svn_commits = True,
          retain_commit_git_svn_parents = False,
          disable_parent_child_ahead_behind_check = False):
  print("cmdop: {0} {1}: entering `{2}`".format(scm_token, cmd_token, configure_dir))

  with tkl.OnExit(lambda: print("cmdop: {0} {1}: leaving `{2}`\n---".format(scm_token, cmd_token, configure_dir))):
    if not git_subtrees_root is None:
      print(' git_subtrees_root: ' + git_subtrees_root)
    if root_only:
      print(' root_only: ' + str(root_only))
    if reset_hard:
      print(' reset_hard: ' + str(reset_hard))

    configure_dir, hub_abbr, scm_type = validate_vars(configure_dir, scm_token)

    configure_dir_relpath = os.path.relpath(configure_dir, CONFIGURE_ROOT).replace('\\', '/')

    # 1. load configuration files from the directory

    yaml_global_vars_pushed = False
    for config_dir in [configure_dir + '/' + LOCAL_CONFIG_DIR_NAME, configure_dir]:
      if not os.path.exists(config_dir):
        continue

      if os.path.isfile(config_dir + '/config.yaml.in'):
        # save all old variable values and remember all newly added variables as a new stack record
        if not yaml_global_vars_pushed:
          cmdop.yaml_push_global_vars()
          yaml_global_vars_pushed = True
        cmdop.yaml_load_config(config_dir, 'config.yaml', to_globals = True, to_environ = False,
          search_by_global_pred_at_third = lambda var_name: cmdop.getglobalvar(var_name))
        break # break on success

    yaml_environ_vars_pushed = False
    for config_dir in [configure_dir + '/' + LOCAL_CONFIG_DIR_NAME, configure_dir]:
      if not os.path.exists(config_dir):
        continue

      if os.path.isfile(config_dir + '/config.env.yaml.in'):
        # save all old variable values and remember all newly added variables as a new stack record
        if not yaml_environ_vars_pushed:
          cmdop.yaml_push_environ_vars()
          yaml_environ_vars_pushed = True
        cmdop.yaml_load_config(config_dir, 'config.env.yaml', to_globals = False, to_environ = True,
          search_by_environ_pred_at_third = lambda var_name: cmdop.getglobalvar(var_name))
        break # break on success

    # 2. Read all `*.HUB_ABBR` and `*.PROJECT_PATH_LIST` variables to collect all project paths.

    scm_list = get_supported_scm_list()

    scm_project_paths_list = None
    all_project_paths_ordered_dict = collections.OrderedDict()

    for scm in scm_list:
      for key, value in g_yaml_globals.expanded_items():
        if key.startswith(scm.upper()) and key.endswith('.HUB_ABBR'):
          scm_token_upper = key[:key.find('.')].upper()

          project_path_list_var = scm_token_upper + '.PROJECT_PATH_LIST'

          project_path_list = g_yaml_globals.get_expanded_value(project_path_list_var)
          if project_path_list is None:
            raise Exception("project path list variable is not defined: `{0}`.".format(project_path_list_var))

          if scm_type == scm:
            scm_project_paths_list = project_path_list
            all_project_paths_ordered_dict.update(collections.OrderedDict().fromkeys(project_path_list))

    # 3. Call a command if a nested directory is in the project paths list.

    ret = 0

    # do action only if not in the root and a command file is present
    if not tkl.compare_file_paths(configure_dir, CONFIGURE_ROOT):
      is_cmdop_dir_in_project_path_list = False
      for project_path in all_project_paths_ordered_dict.keys():
        is_cmdop_dir_in_project_path_list = tkl.compare_file_paths(configure_dir_relpath, project_path)
        if is_cmdop_dir_in_project_path_list:
          break

      if is_cmdop_dir_in_project_path_list:
        nested_ret = 0

        if scm_type == 'svn':
          if cmdop.hasglobalvar(scm_token + '.WCROOT_DIR'):
            if cmd_token == 'cleanup':
              nested_ret = cmdoplib_svn.svn_cleanup(configure_dir, scm_token, bare_args, verbosity = verbosity)
            elif cmd_token == 'update':
              nested_ret = cmdoplib_svn.svn_update(configure_dir, scm_token, bare_args, verbosity = verbosity)
            elif cmd_token == 'checkout':
              nested_ret = cmdoplib_svn.svn_checkout(configure_dir, scm_token, bare_args, verbosity = verbosity)
            elif cmd_token == 'relocate':
              nested_ret = cmdoplib_svn.svn_relocate(configure_dir, scm_token, bare_args, verbosity = verbosity)
            elif cmd_token == 'makedirs':
              nested_ret = cmdoplib_svn.makedirs(configure_dir, scm_token, verbosity = verbosity)
            else:
              raise Exception('unknown command name: ' + str(cmd_token))
        elif scm_type == 'git':
          if cmdop.hasglobalvar(scm_token + '.WCROOT_DIR'):
            if cmd_token == 'init':
              # CAUTION:
              #   * Bare args parameter is only for the root repostiory git init command.
              #
              nested_ret = cmdoplib_gitsvn.git_init(configure_dir, scm_token, bare_args,
                git_subtrees_root = git_subtrees_root,
                root_only = root_only,
                verbosity = verbosity)
            elif cmd_token == 'fetch':
              # CAUTION:
              #   * Bare args parameter is only for the root repostiory git fetch command.
              #
              nested_ret = cmdoplib_gitsvn.git_fetch(configure_dir, scm_token, bare_args,
                git_subtrees_root = git_subtrees_root,
                root_only = root_only, reset_hard = reset_hard,
                prune_empty_git_svn_commits = prune_empty_git_svn_commits,
                verbosity = verbosity)
            elif cmd_token == 'reset':
              # CAUTION:
              #   * Bare args parameter is only for the root repostiory git reset commands.
              #
              nested_ret = cmdoplib_gitsvn.git_reset(configure_dir, scm_token, bare_args,
                git_subtrees_root = git_subtrees_root,
                root_only = root_only,
                reset_hard = reset_hard, cleanup = cleanup_on_reset,
                remove_svn_on_reset = remove_svn_on_reset,
                verbosity = verbosity)
            elif cmd_token == 'pull':
              # CAUTION:
              #   * Bare args parameter is only for the root repository git checkout command.
              #
              nested_ret = cmdoplib_gitsvn.git_pull(configure_dir, scm_token, bare_args,
                git_subtrees_root = git_subtrees_root,
                root_only = root_only,
                reset_hard = reset_hard,
                prune_empty_git_svn_commits = prune_empty_git_svn_commits,
                verbosity = verbosity)
            elif cmd_token == 'push_svn_to_git':
              # CAUTION:
              #   * Bare args parameter is only for the root repository git push command.
              #
              nested_ret = cmdoplib_gitsvn.git_push_from_svn(configure_dir, scm_token, bare_args,
                git_subtrees_root = git_subtrees_root,
                reset_hard = reset_hard,
                prune_empty_git_svn_commits = prune_empty_git_svn_commits,
                retain_commit_git_svn_parents = retain_commit_git_svn_parents,
                verbosity = verbosity,
                disable_parent_child_ahead_behind_check = disable_parent_child_ahead_behind_check)
            elif cmd_token == 'compare_commits':
              # CAUTION:
              #   * Bare args paramter currently has not used here, but exist as a requirement for all functions.
              #
              nested_ret = cmdoplib_gitsvn.git_svn_compare_commits(configure_dir, scm_token, bare_args,
                compare_remote_name, compare_svn_rev,
                git_subtrees_root = git_subtrees_root, svn_subtrees_root = svn_subtrees_root,
                reset_hard = reset_hard, cleanup = cleanup_on_compare,
                verbosity = verbosity)
            elif cmd_token == 'makedirs':
              nested_ret = cmdoplib_gitsvn.makedirs(configure_dir, scm_token,
              verbosity = verbosity)
            else:
              raise Exception('unknown command name: ' + str(cmd_token))
        else:
          raise Exception('unsupported scm name: ' + str(scm_token))

        if nested_ret:
          ret |= 1

    # 4. Call a nested command if a nested directory is in the project paths list.

    configure_all_dirs = []
    for dirpath, dirs, files in os.walk(configure_dir):
      configure_all_dirs.append((dirpath, list(dirs), files))
      dirs.clear() # not recursively

    traversed_cmd_dirs = set()

    for project_path in all_project_paths_ordered_dict.keys():
      is_cmdop_dir_in_project_path_list = False

      for dirpath, dirs, files in configure_all_dirs:
        for dir in dirs:
          dir_str = str(dir)

          # ignore specific directories
          if dir_str.startswith('.'):
            continue

          nested_cmd_dir = os.path.join(dirpath, dir).replace('\\', '/')
          if nested_cmd_dir in traversed_cmd_dirs:
            continue

          is_cmdop_dir_in_project_path_list = tkl.is_file_path_beginswith(project_path + '/', configure_dir_relpath + '/' + dir+ '/')
          if is_cmdop_dir_in_project_path_list:
            break

        if is_cmdop_dir_in_project_path_list:
          break

      if is_cmdop_dir_in_project_path_list:
        traversed_cmd_dirs.add(nested_cmd_dir)
        nested_ret = cmdop(nested_cmd_dir, scm_token, cmd_token, bare_args,
          git_subtrees_root = git_subtrees_root, svn_subtrees_root = svn_subtrees_root,
          compare_remote_name = compare_remote_name, compare_svn_rev = compare_svn_rev,
          root_only = root_only, reset_hard = reset_hard,
          remove_svn_on_reset = remove_svn_on_reset, cleanup_on_reset = cleanup_on_reset, cleanup_on_compare = cleanup_on_compare,
          verbosity = verbosity, prune_empty_git_svn_commits = prune_empty_git_svn_commits,
          retain_commit_git_svn_parents = retain_commit_git_svn_parents)

        if nested_ret:
          ret |= 2

    if yaml_environ_vars_pushed:
      # remove previously added variables and restore previously changed variable values
      cmdop.yaml_pop_environ_vars(True)

    if yaml_global_vars_pushed:
      # remove previously added variables and restore previously changed variable values
      cmdop.yaml_pop_global_vars(True)

  return ret

def on_main_exit():
  if len(g_registered_ignored_errors) > 0:
    print('- Registered ignored errors:')
    for registered_ignored_error in g_registered_ignored_errors:
      print(registered_ignored_error[0])
      print(registered_ignored_error[1])
      print('---')

def main(configure_root, configure_dir, scm_token, cmd_token, bare_args, **kwargs):
  with tkl.OnExit(on_main_exit):
    configure_dir, hub_abbr, scm_type = validate_vars(configure_dir, scm_token)

    configure_dir_relpath = os.path.relpath(configure_dir, configure_root).replace('\\', '/')
    configure_dir_relpath_comp_list = configure_dir_relpath.split('/')
    configure_dir_relpath_comp_list_size = len(configure_dir_relpath_comp_list)

    # load `config.yaml` from `configure_root` up to `configure_dir` (excluded) directory
    if configure_dir_relpath_comp_list_size > 1:
      for config_dir in [configure_root + '/' + LOCAL_CONFIG_DIR_NAME, configure_root]:
        if not os.path.exists(config_dir):
          continue

        if os.path.exists(config_dir + '/config.yaml.in'):
          cmdop.yaml_load_config(config_dir, 'config.yaml', to_globals = True, to_environ = False,
            search_by_global_pred_at_third = lambda var_name: cmdop.getglobalvar(var_name))
          break # break on success

      for i in range(configure_dir_relpath_comp_list_size-1):
        configure_parent_dir = os.path.join(configure_root, *configure_dir_relpath_comp_list[:i+1]).replace('\\', '/')

        for config_dir in [configure_parent_dir + '/' + LOCAL_CONFIG_DIR_NAME, configure_parent_dir]:
          if not os.path.exists(config_dir):
            continue

          if os.path.exists(config_dir + '/config.yaml.in'):
            cmdop.yaml_load_config(config_dir, 'config.yaml', to_globals = True, to_environ = False,
              search_by_global_pred_at_third = lambda var_name: cmdop.getglobalvar(var_name))
            break # break on success

    # load `config.env.yaml` from `configure_root` up to `configure_dir` (excluded) directory
    if configure_dir_relpath_comp_list_size > 1:
      for config_dir in [configure_root + '/' + LOCAL_CONFIG_DIR_NAME, configure_root]:
        if not os.path.exists(config_dir):
          continue

        if os.path.exists(config_dir + '/config.env.yaml.in'):
          cmdop.yaml_load_config(config_dir, 'config.env.yaml', to_globals = False, to_environ = True,
            search_by_environ_pred_at_third = lambda var_name: cmdop.getglobalvar(var_name))
          break # break on success

      for i in range(configure_dir_relpath_comp_list_size-1):
        configure_parent_dir = os.path.join(configure_root, *configure_dir_relpath_comp_list[:i+1]).replace('\\', '/')

        for config_dir in [configure_parent_dir + '/' + LOCAL_CONFIG_DIR_NAME, configure_parent_dir]:
          if not os.path.exists(config_dir):
            continue

          if os.path.exists(config_dir + '/config.env.yaml.in'):
            cmdop.yaml_load_config(config_dir, 'config.env.yaml', to_globals = False, to_environ = True,
              search_by_environ_pred_at_third = lambda var_name: cmdop.getglobalvar(var_name))
            break # break on success

    dir_files_wo_ext = [os.path.splitext(f)[0] for f in os.listdir(configure_dir) if os.path.isfile(f)]
    cmd_file = hub_abbr + '~' + scm_type + '~' + cmd_token

    is_cmd_file_found = False
    for dir_file_wo_ext in dir_files_wo_ext:
      if tkl.compare_file_paths(dir_file_wo_ext, cmd_file):
        is_cmd_file_found = True
        break

    if is_cmd_file_found:
      cmdop(
        configure_dir, scm_token, cmd_token, bare_args,
        **kwargs
      )
    else:
      raise Exception('command file is not found: `{0}`'.format(configure_dir + '/' + cmd_file + '.*'))

# CAUTION:
#   Temporary disabled because of issues in the python xonsh module.
#   See details in the `README_EN.python_xonsh.known_issues.txt` file.
#
#@(pcall, main, CONFIGURE_ROOT, CONFIGURE_DIR, SCM_TOKEN, CMD_TOKEN) | @(CONTOOLS_ROOT + '/unxutils/tee.exe', CONFIGURE_DIR + '/.log/' + os.path.splitext(os.path.split(__file__)[1])[0] + '.' + datetime.now().strftime("%Y'%m'%d_%H'%M'%S''%f")[:-3])

# NOTE:
#   Logging is implemented externally to the python.
#
if __name__ == '__main__':
  # parse arguments
  arg_parser = argparse.ArgumentParser()
  arg_parser.add_argument('--git_subtrees_root', type = str, default = None)            # custom local git subtrees root directory (path)
  arg_parser.add_argument('--svn_subtrees_root', type = str, default = None)            # custom local svn subtrees root directory (path)
  arg_parser.add_argument('-ro', action = 'store_true')                                 # invoke for the root record only (boolean)
  arg_parser.add_argument('--reset_hard', action = 'store_true')                        # use `git reset ...` call with the `--hard` parameter (boolean)
  arg_parser.add_argument('--remove_svn_on_reset', action = 'store_true')               # remove svn cache in `git_reset` function
  arg_parser.add_argument('--cleanup_on_reset', action = 'store_true')                  # use `git clean -d -f` call in `git_reset` function (boolean)
  arg_parser.add_argument('--cleanup_on_compare', action = 'store_true')                # use `git clean -d -f` call in `git_svn_compare_commits` function (boolean)
  arg_parser.add_argument('-v', type = int, default = None)                             # verbosity level: None - defined by VERBOSITY_LEVEL variable,
                                                                                        #   where:0 - normal, 1 - show environment variables upon call to executables
  arg_parser.add_argument('--no_prune_empty', action = 'store_true')                    # not prune empty git-svn commits as by default (boolean)
  arg_parser.add_argument('--compare_remote_name', type = str, default = None)          # compare repository associated with a particular remote name (string)
  arg_parser.add_argument('--compare_svn_rev', type = str, default = None)              # compare a particular svn revision (string)
  arg_parser.add_argument('--retain_commit_git_svn_parents', action = 'store_true')     # Fix the git-svn commit author and other metadata in a child commit and retain all git-svn parents
                                                                                        # instead of not retain them as by default.
                                                                                        # As a result each git repository would contain 2 commits in commit graph per svn revision
                                                                                        # instead of only one (a merged commit plus parent commits as original git-svn fetch commits).
  arg_parser.add_argument('--disable_parent_child_ahead_behind_check', action = 'store_true') # Disables check whether the last pushed parent/child repository commit is ahead/behind to
                                                                                              # the first not pushed child/parent repository commit.

  known_args, unknown_args = arg_parser.parse_known_args(sys.argv[4:])

  for unknown_arg in unknown_args:
    unknown_arg = unknown_arg.lstrip('-')
    for known_arg in vars(known_args).keys():
      if unknown_arg.startswith(known_arg):
        raise Exception('frontend argument is unsafely intersected with the backend argument, you should use an unique name to avoid that: frontrend=`{0}` backend=`{1}`'.format(known_arg, unknown_arg))

  main(
    CONFIGURE_ROOT, CONFIGURE_DIR, SCM_TOKEN, CMD_TOKEN, unknown_args,
    git_subtrees_root = known_args.git_subtrees_root,
    svn_subtrees_root = known_args.svn_subtrees_root,
    compare_remote_name = known_args.compare_remote_name,
    compare_svn_rev = known_args.compare_svn_rev,
    root_only = known_args.ro,
    reset_hard = known_args.reset_hard,
    remove_svn_on_reset = known_args.remove_svn_on_reset,
    cleanup_on_reset = known_args.cleanup_on_reset,
    cleanup_on_compare = known_args.cleanup_on_compare,
    verbosity = known_args.v,
    prune_empty_git_svn_commits = not known_args.no_prune_empty,
    retain_commit_git_svn_parents = known_args.retain_commit_git_svn_parents,
    disable_parent_child_ahead_behind_check = known_args.disable_parent_child_ahead_behind_check
  )
