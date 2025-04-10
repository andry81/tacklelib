import os, sys, shutil, inspect, argparse
import collections
#from datetime import datetime

if not hasattr(globals(), 'tkl_init'):
  # portable import to the global space
  sys.path.append(os.environ['TACKLELIB_PYTHON_SCRIPTS_ROOT'] + '/tacklelib')
  import tacklelib as tkl

  tkl.tkl_init(tkl, global_config = {'log_import_module':os.environ.get('TACKLELIB_LOG_IMPORT_MODULE')})

  # cleanup
  del tkl # must be instead of `tkl = None`, otherwise the variable would be still persist
  sys.path.pop()


# format: [(<header_str>, <stderr_str>), ...]
tkl_declare_global('g_registered_ignored_errors', []) # must be not empty value to save the reference

# basic initialization, loads `config.private.yaml`
tkl_source_module(SOURCE_DIR + '/__init__', '__init__.xsh')


# script arguments parse
for i in [
  ('dir', 1, 'CONFIGURE_OUTPUT_ROOT'),
  ('dir', 2, 'CONFIGURE_ROOT'),
  ('dir', 3, 'CONFIGURE_DIR'),
  ('str', 4, 'SHELL_EXT')]:
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

def validate_vars(configure_in_dir, configure_out_dir, shell_ext):
  if configure_in_dir is None or configure_in_dir == '':
    raise Exception('input configure directory is not defined.')

  if configure_out_dir is None or configure_out_dir == '':
    raise Exception('output configure directory is not defined.')

  if configure_in_dir[-1:] in ['\\', '/']:
    configure_in_dir = configure_in_dir[:-1]

  if configure_in_dir is None or not os.path.isdir(configure_in_dir):
    raise Exception('input configure directory does not exist: `{0}`.'.format(configure_in_dir))

  if not tkl.compare_file_paths(configure_in_dir, configure_out_dir):
    if configure_out_dir[-1:] in ['\\', '/']:
      configure_out_dir = configure_out_dir[:-1]

    if configure_out_dir is None or not os.path.isdir(configure_out_dir):
      raise Exception('output configure directory does not exist: `{0}`.'.format(configure_out_dir))

  if shell_ext is None or shell_ext == '':
    raise Exception('shell file extension must not be empty.'.format(shell_ext))

  return (configure_in_dir, configure_out_dir)

def configure(configure_in_dir, configure_out_dir, shell_ext, bare_args, generate_project_yaml = False, generate_project_scripts = True, chmod_project_scripts = False):
  print("configure: entering `{0}`".format(configure_out_dir))

  with tkl.OnExit(lambda: print("configure: leaving `{0}`\n---".format(configure_out_dir))):
    configure_in_dir, configure_out_dir = validate_vars(configure_in_dir, configure_out_dir, shell_ext)

    if not generate_project_yaml and not generate_project_scripts and not chmod_project_scripts:
      # nothing to do
      return 0

    root_configure_in_dir_relpath = os.path.relpath(CONFIGURE_DIR, CONFIGURE_ROOT).replace('\\', '/')
    root_configure_out_dir_relpath = os.path.join(PROJECT_OUTPUT_PROJECTS_ROOT, root_configure_in_dir_relpath).replace('\\', '/')

    configure_in_dir_relpath = os.path.relpath(configure_in_dir, CONFIGURE_ROOT).replace('\\', '/')
    configure_out_dir_relpath = os.path.join(PROJECT_OUTPUT_PROJECTS_ROOT, configure_in_dir_relpath).replace('\\', '/')

    # 1. Generate configuration files.

    try:
      if generate_project_yaml:
        if os.path.isfile(configure_in_dir + '/config.yaml.in'):
          with open(configure_in_dir + '/config.yaml.in', 'rb') as fsrc, open(configure_out_dir + '/config.yaml', 'wb') as fdst:
            shutil.copyfileobj(fsrc, fdst)

        if os.path.isfile(configure_in_dir + '/config.env.yaml.in'):
          with open(configure_in_dir + '/config.env.yaml.in', 'rb') as fsrc, open(configure_out_dir + '/config.env.yaml', 'wb') as fdst:
            shutil.copyfileobj(fsrc, fdst)

        if os.path.isfile(configure_in_dir + '/git_repos.lst.in'):
          with open(configure_in_dir + '/git_repos.lst.in', 'rb') as fsrc, open(configure_out_dir + '/git_repos.lst', 'wb') as fdst:
            shutil.copyfileobj(fsrc, fdst)

      if generate_project_scripts or chmod_project_scripts:
        # CAUTION:
        #   We must generate `__init__` scripts in all project paths hierarchy:
        #   1. Except the directory above the most top level configure_in_dir (not recursed).
        #
        is_configure_in_dir_not_above_top_level = \
          not tkl.is_file_path_beginswith(root_configure_in_dir_relpath + '/', configure_in_dir_relpath + '/') or
          tkl.compare_file_paths(configure_in_dir, CONFIGURE_ROOT)
        if is_configure_in_dir_not_above_top_level:
          out_file_path = (configure_out_dir + '__init__.' + shell_ext).replace('\\', '/')
          if generate_project_scripts:
            with open(PYXVCS_PROJECT_TMPL_SCRIPTS_ROOT + '__init__.' + shell_ext + '.in', 'rb') as fsrc, open(out_file_path, 'wb') as fdst:
              shutil.copyfileobj(fsrc, fdst)
          if chmod_project_scripts:
            # update script permissions by the chmod utility
            cmdop.call('chmod', ['ug+x', out_file_path], stdout = sys.stdout, stderr = sys.stderr)
            cmdop.call('chmod', ['-R', 'ug+rw', out_file_path], stdout = sys.stdout, stderr = sys.stderr)

    except:
      # `exit` with the parentheses to workaround the issue:
      # `source` xsh file with try/except does hang`:
      # https://github.com/xonsh/xonsh/issues/3301
      exit(255)

    # 2. Load configuration files.

    yaml_global_vars_pushed = False
    if os.path.isfile(configure_in_dir + '/config.yaml.in'):
      # save all old variable values and remember all newly added variables as a new stack record
      if not yaml_global_vars_pushed:
        cmdop.yaml_push_global_vars()
        yaml_global_vars_pushed = True
      cmdop.yaml_load_config(configure_out_dir, 'config.yaml', to_globals = True, to_environ = False,
        search_by_global_pred_at_third = lambda var_name: cmdop.getglobalvar(var_name))

    yaml_environ_vars_pushed = False
    if os.path.isfile(configure_in_dir + '/config.env.yaml.in'):
      # save all old variable values and remember all newly added variables as a new stack record
      if not yaml_environ_vars_pushed:
        cmdop.yaml_push_environ_vars()
        yaml_environ_vars_pushed = True
      cmdop.yaml_load_config(configure_out_dir, 'config.env.yaml', to_globals = False, to_environ = True,
        search_by_environ_pred_at_third = lambda var_name: cmdop.getglobalvar(var_name))

    # 3. Read all `*.HUB_ABBR` and `*.PROJECT_PATH_LIST` variables to collect all project paths and find out what scripts to generate.

    scm_list = get_supported_scm_list()

#...
    all_project_paths_ordered_dict = collections.OrderedDict()
    tmpl_cmdop_files_tuple_list = []

    for scm in scm_list:
      for key, value in g_yaml_globals.expanded_items():
        if key.startswith(scm.upper()) and key.endswith('.HUB_ABBR'):
          scm_token_upper = key[:key.find('.')].upper()

          project_path_list = g_yaml_globals.get_expanded_value(scm_token_upper + '.PROJECT_PATH_LIST')

          all_project_paths_ordered_dict.update(collections.OrderedDict().fromkeys(project_path_list))

          if generate_project_scripts or chmod_project_scripts:
            if len(configure_dir_relpath) > 0 and configure_dir_relpath != '.':
              is_cmd_dir_in_project_path_list = False
              for project_path in project_path_list:
                is_cmd_dir_in_project_path_list = tkl.compare_file_paths(configure_dir_relpath, project_path)
                if is_cmd_dir_in_project_path_list:
                  break

              if not is_cmd_dir_in_project_path_list:
                continue

              for dirpath, dirs, files in os.walk(TMPL_CMDOP_FILES_DIR):
                for file in files:
                  if tkl.is_file_path_beginswith(file, '{HUB}~' + scm + '~') and \
                     tkl.is_file_path_endswith(file, '.' + shell_ext + '.in'):
                    tmpl_cmdop_files_tuple_list.append((scm_token_upper, file, file[:file.rfind('.')].format(HUB = value)))

                dirs.clear() # not recursively

    if generate_project_scripts or chmod_project_scripts:
      # generate vcs command scripts
      for tmpl_cmdop_files_tuple in tmpl_cmdop_files_tuple_list:
        out_file_name = tmpl_cmdop_files_tuple[2]
        out_file_path = os.path.join(configure_dir, out_file_name).replace('\\', '/')
        if generate_project_scripts:
          scm_token_upper = tmpl_cmdop_files_tuple[0]
          in_file_name = tmpl_cmdop_files_tuple[1]
          in_file_path = os.path.join(TMPL_CMDOP_FILES_DIR, in_file_name).replace('\\', '/')
          with open(in_file_path, 'rb') as in_file, open(out_file_path, 'wb') as out_file:
            in_file_content = in_file.read()
            out_file.write(in_file_content.replace(b'{SCM_TOKEN}', scm_token_upper.encode('utf-8')))
        if chmod_project_scripts:
          # update script permissions by the chmod utility
          cmdop.call('chmod', ['ug+x', out_file_path], stdout = sys.stdout, stderr = sys.stderr)
          cmdop.call('chmod', ['-R', 'ug+rw', out_file_path], stdout = sys.stdout, stderr = sys.stderr)

    # 4. Call a nested command if a nested directory is in the project paths list.

    ret = 0

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

          is_cmdop_dir_in_project_path_list = tkl.is_file_path_beginswith(project_path + '/', configure_dir_relpath + '/' + dir + '/')
          if is_cmdop_dir_in_project_path_list:
            break

        if is_cmdop_dir_in_project_path_list:
          break

      if is_cmdop_dir_in_project_path_list:
        traversed_cmd_dirs.add(nested_cmd_dir)
        nested_ret = configure(nested_cmd_dir, shell_ext, bare_args,
          generate_project_yaml = generate_project_yaml,
          generate_project_scripts = generate_project_scripts,
          chmod_project_scripts = chmod_project_scripts)

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

def main(configure_root, configure_dir, shell_ext, bare_args, generate_config_yaml = False, generate_project_yaml = False, **kwargs):
  with tkl.OnExit(on_main_exit):
    configure_dir = validate_vars(configure_dir, shell_ext)

    configure_dir_relpath = os.path.relpath(configure_dir, configure_root).replace('\\', '/')
    configure_dir_relpath_comp_list = configure_dir_relpath.split('/')
    configure_dir_relpath_comp_list_size = len(configure_dir_relpath_comp_list)

    # generate (optional) and load `config.yaml` from `configure_root` up to `configure_dir` (excluded) directory
    if configure_dir_relpath_comp_list_size > 1:
      for config_dir in [configure_root + '/' + LOCAL_CONFIG_DIR_NAME, configure_root]:
        if not os.path.exists(config_dir):
          continue

        if os.path.exists(config_dir + '/config.yaml.in'):
          if generate_config_yaml:
            with open(config_dir + '/config.yaml.in', 'rb') as fsrc, open(config_dir + '/config.yaml', 'wb') as fdst:
              shutil.copyfileobj(fsrc, fdst)

          cmdop.yaml_load_config(config_dir, 'config.yaml', to_globals = True, to_environ = False,
            search_by_global_pred_at_third = lambda var_name: cmdop.getglobalvar(var_name))
          break # break on success

      for i in range(configure_dir_relpath_comp_list_size-1):
        configure_parent_dir = os.path.join(configure_root, *configure_dir_relpath_comp_list[:i+1]).replace('\\', '/')

        for config_dir in [configure_parent_dir + '/' + LOCAL_CONFIG_DIR_NAME, configure_parent_dir]:
          if not os.path.exists(config_dir):
            continue

          if os.path.exists(config_dir + '/config.yaml.in'):
            if generate_project_yaml:
              with open(config_dir + '/config.yaml.in', 'rb') as fsrc, open(config_dir + '/config.yaml', 'wb') as fdst:
                shutil.copyfileobj(fsrc, fdst)

            cmdop.yaml_load_config(config_dir, 'config.yaml', to_globals = True, to_environ = False,
              search_by_global_pred_at_third = lambda var_name: cmdop.getglobalvar(var_name))
            break # break on success

    # generate (optional) and load `config.env.yaml` from `configure_root` up to `configure_dir` (excluded) directory
    if configure_dir_relpath_comp_list_size > 1:
      for config_dir in [configure_root + '/' + LOCAL_CONFIG_DIR_NAME, configure_root]:
        if not os.path.exists(config_dir):
          continue

        if os.path.exists(config_dir + '/config.env.yaml.in'):
          if generate_config_yaml:
            with open(config_dir + '/config.env.yaml.in', 'rb') as fsrc, open(config_dir + '/config.env.yaml', 'wb') as fdst:
              shutil.copyfileobj(fsrc, fdst)

          cmdop.yaml_load_config(config_dir, 'config.env.yaml', to_globals = False, to_environ = True,
            search_by_environ_pred_at_third = lambda var_name: cmdop.getglobalvar(var_name))
          break # break on success

      for i in range(configure_dir_relpath_comp_list_size-1):
        configure_parent_dir = os.path.join(configure_root, *configure_dir_relpath_comp_list[:i+1]).replace('\\', '/')

        for config_dir in [configure_parent_dir + '/' + LOCAL_CONFIG_DIR_NAME, configure_parent_dir]:
          if not os.path.exists(config_dir):
            continue

          if os.path.exists(config_dir + '/config.env.yaml.in'):
            if generate_project_yaml:
              with open(config_dir + '/config.env.yaml.in', 'rb') as fsrc, open(config_dir + '/config.env.yaml', 'wb') as fdst:
                shutil.copyfileobj(fsrc, fdst)

            cmdop.yaml_load_config(config_dir, 'config.env.yaml', to_globals = False, to_environ = True,
              search_by_environ_pred_at_third = lambda var_name: cmdop.getglobalvar(var_name))
            break # break on success

    configure(configure_dir, shell_ext, bare_args, generate_project_yaml = generate_project_yaml, **kwargs)

# CAUTION:
#   Temporary disabled because of issues in the python xonsh module.
#   See details in the `README_EN.python_xonsh.known_issues.txt` file.
#
#@(pcall, main, CONFIGURE_ROOT, CONFIGURE_DIR) | @(CONTOOLS_UTILS_BIN_ROOT + '/unxutils/tee.exe', CONFIGURE_DIR + '/.log/' + os.path.splitext(os.path.split(__file__)[1])[0] + '.' + datetime.now().strftime("%Y'%m'%d_%H'%M'%S''%f")[:-3])

# NOTE:
#   Logging is implemented externally to the python.
#
if __name__ == '__main__':
  # parse arguments
  arg_parser = argparse.ArgumentParser()
  arg_parser.add_argument('--gen_config_yaml', action = 'store_true')           # generate public root `config.yaml`, `config.env.yaml` configuration files, except the `config.private.yaml` configuration file
  arg_parser.add_argument('--gen_project_configs', action = 'store_true')       # generate project configuration files: `config.yaml`, `git_repos.lst` and etc
  arg_parser.add_argument('--gen_projects_scripts', action = 'store_true')      # generate project script files
  arg_parser.add_argument('--chmod_project_scripts', action = 'store_true')     # set permissions for project script files

  known_args, unknown_args = arg_parser.parse_known_args(sys.argv[3:])

  for unknown_arg in unknown_args:
    unknown_arg = unknown_arg.lstrip('-')
    for known_arg in vars(known_args).keys():
      if unknown_arg.startswith(known_arg):
        raise Exception('frontend argument is unsafely intersected with the backend argument, you should use an unique name to avoid that: frontrend=`{0}` backend=`{1}`'.format(known_arg, unknown_arg))

  main(
    CONFIGURE_ROOT, CONFIGURE_DIR, SHELL_EXT, unknown_args,
    generate_config_yaml = known_args.gen_config_yaml,
    generate_project_yaml = known_args.gen_project_yaml,
    generate_project_scripts = known_args.gen_projects_scripts,
    chmod_project_scripts = known_args.chmod_project_scripts
  )
