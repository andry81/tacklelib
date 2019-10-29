# python module for commands with extension modules usage: tacklelib, yaml

tkl_import_module(TACKLELIB_ROOT, 'tacklelib.yaml.py', 'tkl')
tkl_source_module(SOURCE_DIR, 'cmdoplib.std.xsh')

import os, shutil, yaml

if 'g_yaml_globals' not in globals():
  globals()['g_yaml_globals'] = tkl.YamlEnv()
if 'g_yaml_environ' not in globals():
  globals()['g_yaml_environ'] = tkl.YamlEnv()

def yaml_push_global_vars():
  globals()['g_yaml_globals'].push_unexpanded_vars()

def yaml_pop_global_vars(reexpand_vars, delvar_pred = None):
  globals()['g_yaml_globals'].pop_unexpanded_vars(reexpand_vars, lambda key: delvar(key) if delvar_pred is None else delvar_pred(key))

def yaml_update_global_vars(to_load_yaml_dict = None, setvar_pred = None):
  current_globals = globals()

  yaml_globals = current_globals['g_yaml_globals']
  if to_load_yaml_dict:
    yaml_globals.load(to_load_yaml_dict)
  yaml_globals.expand(list_as_cmdline = False)

  if setvar_pred is None:
    for key, value in yaml_globals.expanded_items():
      setglobalvar(key, value)
  else:
    for key, value in yaml_globals.expanded_items():
      setvar_pred(key, value)

def yaml_push_environ_vars():
  globals()['g_yaml_environ'].push_unexpanded_vars()

def yaml_pop_environ_vars(reexpand_vars, delvar_pred = None):
  globals()['g_yaml_environ'].pop_unexpanded_vars(reexpand_vars, lambda key: delvar(key) if delvar_pred is None else delvar_pred(key))

def yaml_update_environ_vars(to_load_yaml_dict = None, use_global_vars_to_expand = True, setvar_pred = None):
  current_globals = globals()

  yaml_environ = current_globals['g_yaml_environ']
  if to_load_yaml_dict:
    yaml_environ.load(to_load_yaml_dict)

  if use_global_vars_to_expand:
    yaml_globals = current_globals['g_yaml_globals']
    yaml_environ.expand(expand_dict = yaml_globals.expanded_vars, list_as_cmdline = True)
  else:
    yaml_environ.expand(list_as_cmdline = True)

  if setvar_pred is None:
    for key, value in yaml_environ.expanded_items():
      setenvvar(key, value)
      print('- declare environment variable: ' + str(key) + '=`' + str(value) + '`')
  else:
    for key, value in yaml_environ.expanded_items():
      setvar_pred(key, value)
      print('- declare environment variable: ' + str(key) + '=`' + str(value) + '`')

def yaml_load_config(config_dir, config_file, to_globals = True, to_environ = False, set_global_var_pred = None, set_environ_var_pred = None):
  if not os.path.isdir(config_dir):
    raise Exception('config_dir is not existing directory: `{}`'.format(config_dir))
  if config_file == '':
    raise Exception('config_file is not defined')
  if not to_globals and not to_environ:
    raise Exception('either to_globals or to_environ must be True')

  config_file_out = os.path.join(config_dir, config_file).replace('\\','/')
  config_file_in = '{0}.in'.format(config_file_out)

  if not os.path.exists(config_file_out) and os.path.exists(config_file_in):
    print('"{0}" -> "{1}"'.format(config_file_in, config_file_out))
    try:
      shutil.copyfile(config_file_in, config_file_out)
    except:
      # `exit` with the parentheses to workaround the issue:
      # `source` xsh file with try/except does hang`:
      # https://github.com/xonsh/xonsh/issues/3301
      exit(255)

  config_yaml = None

  if os.path.isfile(config_file_out):
    if os.path.splitext(config_file)[1] in ['.yaml', '.yml']:
      with open(config_file_out, 'rt') as config_file_out_handle:
        config_file_out_content = config_file_out_handle.read()

        config_yaml = yaml.load(config_file_out_content, Loader=yaml.FullLoader)
    else:
      raise Exception('config file is not a YAML configuration file: `{0}`'.format(config_file_out))
  else:
    raise Exception('config file is not found: `{0}`'.format(config_file_out))

  # update global variables at first
  if to_globals:
    yaml_update_global_vars(config_yaml, setvar_pred = set_global_var_pred)

  if to_environ:
    yaml_update_environ_vars(config_yaml, setvar_pred = set_environ_var_pred)

def yaml_expand_value(value):
  return globals()['g_yaml_globals'].expand_value(value)
