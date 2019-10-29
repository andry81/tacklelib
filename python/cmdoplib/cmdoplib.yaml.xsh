# python module for commands with extension modules usage: tacklelib, yaml

tkl_import_module(TACKLELIB_ROOT, 'tacklelib.yaml.py', 'tkl')
tkl_source_module(SOURCE_DIR, 'cmdoplib.std.xsh')

import os, shutil, yaml

if 'g_yaml_env' not in globals():
  globals()['g_yaml_env'] = tkl.YamlEnv()

def yaml_push_global_vars():
  globals()['g_yaml_env'].push_unexpanded_vars()

def yaml_pop_global_vars(reexpand_vars, delvar_pred = None):
  globals()['g_yaml_env'].pop_unexpanded_vars(reexpand_vars, lambda key: delvar(key) if delvar_pred is None else delvar_pred(key))

def yaml_update_global_vars(yaml_dict = None, setvar_pred = None):
  current_globals = globals()

  yaml_env = current_globals['g_yaml_env']
  if yaml_dict:
    yaml_env.load(yaml_dict)
  yaml_env.expand()

  if setvar_pred is None:
    for key, value in current_globals['g_yaml_env'].expanded_items():
      setvar(key, value)
  else:
    for key, value in current_globals['g_yaml_env'].expanded_items():
      setvar_pred(key, value)

def yaml_load_config(config_dir, config_file):
  if not os.path.isdir(config_dir):
    raise Exception('config_dir is not existing directory: `{}`'.format(config_dir))
  if config_file == '':
    raise Exception('config_file is not defined')

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

  yaml_update_global_vars(config_yaml)

def yaml_expand_value(value):
  return globals()['g_yaml_env'].expand_value(value)
