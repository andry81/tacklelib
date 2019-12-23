# python module for commands with extension modules usage: tacklelib, yaml

tkl_import_module(TACKLELIB_ROOT, 'tacklelib.yaml.py', 'tkl')

tkl_source_module(CMDOPLIB_ROOT, 'cmdoplib.std.xsh', reimport_if_being_imported = True)

tkl_declare_global('g_yaml_globals', tkl.YamlEnv()) # must be not empty value to save the reference
tkl_declare_global('g_yaml_environ', tkl.YamlEnv()) # must be not empty value to save the reference

import os, shutil, yaml

def yaml_push_global_vars():
  g_yaml_globals.push_unexpanded_vars()

def yaml_pop_global_vars(reexpand_vars, delvar_pred = None):
  g_yaml_globals.pop_unexpanded_vars(reexpand_vars, lambda key: delglobalvar(key) if delvar_pred is None else delvar_pred(key))

def yaml_update_global_vars(load_second_yaml_dict = None, search_by_pred_at_third = None, setvar_pred = None):
  if load_second_yaml_dict:
    g_yaml_globals.load(load_second_yaml_dict)
  g_yaml_globals.expand(search_by_pred_at_third = search_by_pred_at_third, list_as_cmdline = False)

  if setvar_pred is None:
    for key, value in g_yaml_globals.expanded_items():
      setglobalvar(key, value)
  else:
    for key, value in g_yaml_globals.expanded_items():
      setvar_pred(key, value)

def yaml_is_compound_environ_var_value(value):
  return isinstance(value, dict)

def yaml_push_environ_vars():
  g_yaml_environ.push_unexpanded_vars()

def yaml_pop_environ_vars(reexpand_vars, delvar_pred = None):
  g_yaml_environ.pop_unexpanded_vars(reexpand_vars,
    lambda key: (delenvvar(key) if delvar_pred is None else delvar_pred(key)) \
    if not yaml_is_compound_environ_var_value(g_yaml_environ.unexpanded_vars[key]) else None)

def yaml_update_environ_vars(load_second_yaml_dict = None, search_in_yaml_global_vars_at_second = True, search_by_pred_at_third = None, setvar_pred = None):
  if load_second_yaml_dict:
    g_yaml_environ.load(load_second_yaml_dict)

  if search_in_yaml_global_vars_at_second:
    g_yaml_environ.expand(search_in_expand_dict_at_second = g_yaml_globals.expanded_vars, search_by_pred_at_third = search_by_pred_at_third, ignore_types = [dict], list_as_cmdline = True)
  else:
    g_yaml_environ.expand(search_by_pred_at_third = search_by_pred_at_third, ignore_types = [dict], list_as_cmdline = True)

  if setvar_pred is None:
    for key, value in g_yaml_environ.expanded_items():
      # ignore compound values, leave the parse of it to the `call` function
      if not yaml_is_compound_environ_var_value(value):
        setenvvar(key, value)
        print('- declare environment variable: ' + str(key) + '=`' + str(value) + '`')
  else:
    for key, value in g_yaml_environ.expanded_items():
      # ignore compound values, leave the parse of it to the `call` function
      if not yaml_is_compound_environ_var_value(value):
        setvar_pred(key, value)
        print('- declare environment variable: ' + str(key) + '=`' + str(value) + '`')

def yaml_load_config(config_dir, config_file, to_globals = True, to_environ = False,
                     search_by_global_pred_at_third = None, search_by_environ_pred_at_third = None,
                     set_global_var_pred = None, set_environ_var_pred = None):
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
    yaml_update_global_vars(config_yaml, search_by_pred_at_third = search_by_global_pred_at_third, setvar_pred = set_global_var_pred)
  elif not search_by_global_pred_at_third is None:
    raise Exception('parameters inconsistency: search_by_global_pred_at_third is not None, when to_globals is None')

  if to_environ:
    yaml_update_environ_vars(config_yaml, search_by_pred_at_third = search_by_environ_pred_at_third, setvar_pred = set_environ_var_pred)
  elif not search_by_environ_pred_at_third is None:
    raise Exception('parameters inconsistency: search_by_environ_pred_at_third is not None, when to_environ is None')

def yaml_expand_global_string(str_value, search_in_expand_dict_at_second = None,
                              search_by_pred_at_third = lambda var_name: getglobalvar(var_name), list_as_cmdline = False):
  return g_yaml_globals.expand_string(str_value,
    search_in_expand_dict_at_second = search_in_expand_dict_at_second, search_by_pred_at_third = search_by_pred_at_third)

def yaml_expand_global_list(list_value, search_in_expand_dict_at_second = None,
                            search_by_pred_at_third = lambda var_name: getglobalvar(var_name), list_as_cmdline = False):
  return g_yaml_globals.expand_list(list_value,
    search_in_expand_dict_at_second = search_in_expand_dict_at_second, search_by_pred_at_third = search_by_pred_at_third,
    list_as_cmdline = list_as_cmdline)

def yaml_expand_global_dict(dict_value, search_in_expand_dict_at_second = None,
                            search_by_pred_at_third = lambda var_name: getglobalvar(var_name), list_as_cmdline = False):
  return g_yaml_globals.expand_dict(dict_value,
    search_in_expand_dict_at_second = search_in_expand_dict_at_second, search_by_pred_at_third = search_by_pred_at_third,
    list_as_cmdline = list_as_cmdline)

def yaml_expand_environ_string(str_value, search_in_yaml_global_vars_at_second = True,
                               search_by_pred_at_third = lambda var_name: getglobalvar(var_name), list_as_cmdline = True):
  if search_in_yaml_global_vars_at_second:
    search_in_expand_dict_at_second = g_yaml_globals.expanded_vars
  else:
    search_in_expand_dict_at_second = None
  return g_yaml_environ.expand_string(str_value,
    search_in_expand_dict_at_second = search_in_expand_dict_at_second, search_by_pred_at_third = search_by_pred_at_third)

def yaml_expand_environ_list(list_value, search_in_yaml_global_vars_at_second = True,
                             search_by_pred_at_third = lambda var_name: getglobalvar(var_name), list_as_cmdline = True):
  if search_in_yaml_global_vars_at_second:
    search_in_expand_dict_at_second = g_yaml_globals.expanded_vars
  else:
    search_in_expand_dict_at_second = None
  return g_yaml_environ.expand_list(list_value,
    search_in_expand_dict_at_second = search_in_expand_dict_at_second, search_by_pred_at_third = search_by_pred_at_third,
    list_as_cmdline = list_as_cmdline)

def yaml_expand_environ_dict(dict_value, search_in_yaml_global_vars_at_second = True,
                             search_by_pred_at_third = lambda var_name: getglobalvar(var_name), list_as_cmdline = True):
  if search_in_yaml_global_vars_at_second:
    search_in_expand_dict_at_second = g_yaml_globals.expanded_vars
  else:
    search_in_expand_dict_at_second = None
  return g_yaml_environ.expand_dict(dict_value,
    search_in_expand_dict_at_second = search_in_expand_dict_at_second, search_by_pred_at_third = search_by_pred_at_third,
    list_as_cmdline = list_as_cmdline)

def yaml_expand_environ_value(value, search_in_yaml_global_vars_at_second = True,
                              search_by_pred_at_third = lambda var_name: getglobalvar(var_name), list_as_cmdline = True):
  if isinstance(value, int) or isinstance(value, float):
    return str(value)
  if isinstance(value, str):
    return yaml_expand_environ_string(value,
      search_in_yaml_global_vars_at_second = search_in_yaml_global_vars_at_second, search_by_pred_at_third = search_by_pred_at_third,
      list_as_cmdline = list_as_cmdline)
  elif isinstance(value, list):
    return yaml_expand_environ_list(value,
      search_in_yaml_global_vars_at_second = search_in_yaml_global_vars_at_second, search_by_pred_at_third = search_by_pred_at_third,
      list_as_cmdline = list_as_cmdline)
  elif isinstance(value, dict):
    return yaml_expand_environ_dict(value,
      search_in_yaml_global_vars_at_second = search_in_yaml_global_vars_at_second, search_by_pred_at_third = search_by_pred_at_third,
      list_as_cmdline = list_as_cmdline)

  raise Exception('unknown value format: ' + str(type(value)))

def yaml_get_environ_unexpanded_vars():
  return g_yaml_environ.unexpanded_vars

def yaml_remove_environ_unexpanded_var(var_name, reexpand_vars, list_as_cmdline = True):
  yaml_unexpanded_vars = g_yaml_environ.unexpanded_vars
  if not reexpand_vars:
    yaml_unexpanded_vars.pop(var_name, None) # a bit faster
  else:
    if var_name in yaml_unexpanded_vars:
      del yaml_unexpanded_vars[var_name]
      g_yaml_environ.expand(list_as_cmdline = list_as_cmdline)
